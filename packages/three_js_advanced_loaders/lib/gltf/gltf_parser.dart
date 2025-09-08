import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:three_js_advanced_loaders/gltf/gltf_extensions.dart';

import 'gltf_mesh_standard_sg_material.dart';
import 'gltf_helper.dart';
import 'gltf_cubic_spline_interpolant.dart';
import 'gltf_registry.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'gltf_loader.dart';

/* GLTF PARSER */
class GLTFParser {
  late FileLoader fileLoader;
  late Map<String, dynamic> json;
  Map<String,dynamic> extensions = {};
  Map<String,dynamic> plugins = {};
  late Map<String, dynamic> options;
  GLTFRegistry cache = GLTFRegistry();
  Map associations = {};
  Map<String,dynamic> primitiveCache = {};
  Map<String,dynamic> meshCache = {"refs": {}, "uses": {}};
  Map<String,dynamic> cameraCache = {"refs": {}, "uses": {}};
  Map<String,dynamic> lightCache = {"refs": {}, "uses": {}};
  Map<String,dynamic> nodeNamesUsed = {};
  late TextureLoader textureLoader;

  Function? createNodeAttachment;
  Function? extendMaterialParams;
  Function? loadBufferView;

  Map textureCache = {};
  Map sourceCache = {};

  GLTFParser get parser => this;

  GLTFParser(Map<String, dynamic>? json, Map<String, dynamic>? options) {
    this.json = json ?? {};
    this.options = options ?? {};

    // Use an ImageBitmapLoader if imageBitmaps are supported. Moves much of the
    // expensive work of uploading a texture to the GPU off the main thread.
    // if ( createImageBitmap != null && /Firefox/.test( navigator.userAgent ) == false ) {
    //   this.textureLoader = ImageBitmapLoader( this.options.manager );
    // } else {
    textureLoader = TextureLoader(manager: this.options["manager"], flipY: this.options['flipY']);
    // }

    textureLoader.setCrossOrigin(this.options["crossOrigin"]);
    textureLoader.setRequestHeader(this.options["requestHeader"]);

    fileLoader = FileLoader(this.options["manager"]);
    fileLoader.setResponseType('arraybuffer');

    if (this.options["crossOrigin"] == 'use-credentials') {
      fileLoader.setWithCredentials(true);
    }

    loadBufferView = loadBufferView2;
  }

  void setExtensions(Map<String,dynamic> extensions) {
    this.extensions = extensions;
  }

  void setPlugins(Map<String,dynamic> plugins) {
    this.plugins = plugins;
  }

  Future<GLTFData> parse() async {
    final parser = this;
    final json = this.json;
    final extensions = this.extensions;

    // Clear the loader cache
    cache.removeAll();

    // Mark the special nodes/meshes in json for efficient parse
    _invokeAll((ext) {
      return ext?.markDefs != null && ext?.markDefs?.call() != null;
    });

    final scenes = await getDependencies('scene');
    final animations = await getDependencies('animation');
    final cameras = await getDependencies('camera');

    final result = GLTFData(
      scene: scenes[json["scene"] ?? 0],
      scenes: scenes,
      animations: animations as List?,
      cameras: cameras as List?,
      asset: json["asset"],
      parser: parser,
      userData: {}
    );

    addUnknownExtensionsToUserData(extensions, result, json);

    assignExtrasToUserData(result, json);

    for (final scene in result.scenes ) {
      scene.updateMatrixWorld();
    }

    return result;
  }

  ///
  /// Marks the special nodes/meshes in json for efficient parse.
  ///
  void markDefs() {
    final nodeDefs = json["nodes"] ?? [];
    final skinDefs = json["skins"] ?? [];
    final meshDefs = json["meshes"] ?? [];

    // Nothing in the node definition indicates whether it is a Bone or an
    // Object3D. Use the skins' joint references to mark bones.
    for (int skinIndex = 0, skinLength = skinDefs.length;
        skinIndex < skinLength;
        skinIndex++) {
      final joints = skinDefs[skinIndex]["joints"];

      for (int i = 0, il = joints.length; i < il; i++) {
        nodeDefs[joints[i]]["isBone"] = true;
      }
    }

    // Iterate over all nodes, marking references to shared resources,
    // as well as skeleton joints.
    for (int nodeIndex = 0, nodeLength = nodeDefs.length;
        nodeIndex < nodeLength;
        nodeIndex++) {
      Map<String, dynamic> nodeDef = nodeDefs[nodeIndex];

      if (nodeDef["mesh"] != null) {
        addNodeRef(meshCache, nodeDef["mesh"]);

        // Nothing in the mesh definition indicates whether it is
        // a SkinnedMesh or Mesh. Use the node's mesh reference
        // to mark SkinnedMesh if node has skin.
        if (nodeDef["skin"] != null) {
          meshDefs[nodeDef["mesh"]]["isSkinnedMesh"] = true;
        }
      }

      if (nodeDef["camera"] != null) {
        addNodeRef(cameraCache, nodeDef["camera"]);
      }
    }
  }

  ///
  /// Counts references to shared node / Object3D resources. These resources
  /// can be reused, or "instantiated", at multiple nodes in the scene
  /// hierarchy. Mesh, Camera, and Light instances are instantiated and must
  /// be marked. Non-scenegraph resources (like Materials, Geometries, and
  /// Textures) can be reused directly and are not marked here.
  ///
  /// Example: CesiumMilkTruck sample model reuses "Wheel" meshes.
  ///
  void addNodeRef(Map<String,dynamic> cache, int? index) {
    if (index == null) return;

    if (cache["refs"][index] == null) {
      cache["refs"][index] = cache["uses"][index] = 0;
    }

    cache["refs"][index]++;
  }

  /// Returns a reference to a shared resource, cloning it if necessary.
  Object3D getNodeRef(Map<String,dynamic> cache, int index, Object3D object) {
    if (cache["refs"][index] == null || cache["refs"][index] <= 1) return object;
    final ref = object.clone();

		void updateMappings(Object3D original, Object3D clone ){
			final mappings = this.associations[original];
			if ( mappings != null ) {
				this.associations[clone] = mappings;
			}

			for ( final child in original.children) {
				updateMappings( child, clone.children[ i ] );
			}
		};

		updateMappings( object, ref );

    ref.name += '_instance_${(cache["uses"][index]++)}';
    return ref;
  }

  Future _invokeOne(Function func) async {
    final extensions = plugins.values.toList();
    extensions.add(this);

    for (int i = 0; i < extensions.length; i++) {
      final result = await func(extensions[i]);
      if (result != null) return result;
    }
  }

  Future<List> _invokeAll(Function func) async {
    final extensions = plugins.values.toList();
    extensions.insert(0, this);

    final results = [];

    for (int i = 0; i < extensions.length; i++) {
      final result = await func(extensions[i]);
      if (result != null) results.add(result);
    }

    return results;
  }

  ///
  /// Requests the specified dependency asynchronously, with caching.
  /// @param {string} type
  /// @param {number} index
  /// @return {Promise<Object3D|Material|THREE.Texture|AnimationClip|ArrayBuffer|Object>}
  ///
  Future getDependency(String type, int index) async {
    final cacheKey = '$type:$index';
    dynamic dependency = cache.get(cacheKey);

    if (dependency == null) {
      switch (type) {
        case 'scene':
          dependency = await loadScene(index);
          break;

        case 'node':
					dependency = await _invokeOne(( ext ) async{
						return ext?.loadNode != null ? await ext!.loadNode(index) : null;
					});
          //dependency = await loadNode(index);
          break;

        case 'mesh':
          dependency = await _invokeOne((ext) async {
            return ext?.loadMesh != null ? await ext!.loadMesh(index) : null;
          });
          break;

        case 'accessor':
          dependency = await loadAccessor(index);
          break;

        case 'bufferView':
          dependency = await _invokeOne((ext) async {
            return ext?.loadBufferView != null? await ext?.loadBufferView?.call(index): null;
          });
          break;

        case 'buffer':
          dependency = await loadBuffer(index);
          break;

        case 'material':
          dependency = await _invokeOne((ext) async {
            return ext?.loadMaterial != null
                ? await ext?.loadMaterial?.call(index)
                : null;
          });
          break;

        case 'texture':
          dependency = await _invokeOne((ext) async {
            return ext?.loadTexture != null
                ? await ext?.loadTexture?.call(index)
                : null;
          });
          break;

        case 'skin':
          dependency = await loadSkin(index);
          break;

        case 'animation':
          dependency = await _invokeOne((ext) async {
            return ext?.loadAnimation != null? await ext?.loadAnimation?.call(index): null;
          });
          //dependency = await loadAnimation(index);
          break;

        case 'camera':
          dependency = loadCamera(index);
          break;

        default:
					dependency = this._invokeOne(( ext ) {
						return ext != this && ext.getDependency && ext.getDependency( type, index );
					} );

					if ( !dependency ) {
						throw ('GLTFParser getDependency Unknown type: $type');
					}

					break;
          
      }

      cache.add(cacheKey, dependency);
    }

    return dependency;
  }

  ///
  /// Requests all dependencies of the specified type asynchronously, with caching.
  /// @param {string} type
  /// @return {Promise<Array<Object>>}
  ///
  Future<List> getDependencies(String type) async {
    final dependencies = cache.get(type);

    if (dependencies != null) {
      return dependencies;
    }
    
    final defs = json[type + (type == 'mesh' ? 'es' : 's')] ?? [];
    List otherDependencies = [];

    int l = defs.length;

    for (int i = 0; i < l; i++) {
      final dep1 = await getDependency(type, i);
      otherDependencies.add(dep1);
    }

    cache.add(type, otherDependencies);

    return otherDependencies;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#buffers-and-buffer-views
  /// @param {number} bufferIndex
  /// @return {Promise<ArrayBuffer>}
  ///
  loadBuffer(int bufferIndex) async {
    Map<String, dynamic> bufferDef = json["buffers"][bufferIndex];
    final loader = fileLoader;

    if (bufferDef["type"] != null && bufferDef["type"] != 'arraybuffer') {
      throw ('GLTFLoader: ${bufferDef["type"]} buffer type is not supported.');
    }

    // If present, GLB container is required to be the first buffer.
    if (bufferDef["uri"] == null && bufferIndex == 0) {
      return extensions[gltfExtensions["KHR_BINARY_GLTF"]].body;
    }

    final options = this.options;
    if(bufferDef["uri"] != null && options["path"] != null){
      final url = LoaderUtils.resolveURL(bufferDef["uri"], options["path"]);
      final res = await loader.unknown(url);

      return res?.data;
    }

    return null;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#buffers-and-buffer-views
  /// @param {number} bufferViewIndex
  /// @return {Promise<ArrayBuffer>}
  ///
  int i = 0;
  Future<ByteBuffer?> loadBufferView2(int bufferViewIndex) async {
    final bufferViewDef = json["bufferViews"][bufferViewIndex];
    final buffer = await getDependency('buffer', bufferViewDef["buffer"]);
    final byteLength = bufferViewDef["byteLength"] ?? 0;
    final byteOffset = bufferViewDef["byteOffset"] ?? 0;
    // use sublist(0) clone list, if not when load texture decode image will fail ? and with no error, return null image
    ByteBuffer? otherBuffer;
    if (buffer is TypedData) {
      if(kIsWasm){
        otherBuffer = buffer.buffer.asUint8List().sublist(byteOffset, byteOffset + byteLength).buffer;
      }
      else{
        otherBuffer = Uint8List.view(buffer.buffer, byteOffset, byteLength).sublist(0).buffer;
      }
    } 
    else if(buffer != null && buffer is ByteBuffer){
      if(kIsWasm){
        otherBuffer = buffer.asUint8List().sublist(byteOffset, byteOffset + byteLength).buffer;
      }
      else{
        otherBuffer = Uint8List.view(buffer, byteOffset, byteLength).sublist(0).buffer;
      }
    }
    return otherBuffer;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#accessors
  /// @param {number} accessorIndex
  /// @return {Promise<BufferAttribute|InterleavedBufferAttribute>}
  ///
  loadAccessor(accessorIndex) async {
    final parser = this;
    final json = this.json;
    Map<String, dynamic> accessorDef = this.json["accessors"][accessorIndex];

    if (accessorDef["bufferView"] == null && accessorDef["sparse"] == null) {
			final itemSize = webglTypeSize[ accessorDef['type'] ];
			final TypedArray = webglComponentTypes[ accessorDef['componentType'] ]!;
			final normalized = accessorDef['normalized'] == true;

			final array = TypedArray( accessorDef['count'] * itemSize );
			return BufferAttribute.fromUnknown(array, itemSize!, normalized );
    }

    dynamic bufferView;
    if (accessorDef["bufferView"] != null) {
      bufferView = await getDependency('bufferView', accessorDef["bufferView"]);
    } 
    else {
      bufferView = null;
    }

    dynamic sparseIndicesBufferView;
    dynamic sparseValuesBufferView;

    if (accessorDef["sparse"] != null) {
      final sparse = accessorDef["sparse"];
      sparseIndicesBufferView = await getDependency('bufferView', sparse["indices"]["bufferView"]);
      sparseValuesBufferView = await getDependency('bufferView', sparse["values"]["bufferView"]);
    }

    int itemSize = webglTypeSize[accessorDef["type"]]!;
    final typedArray = GLTypeData(accessorDef["componentType"]);

    // For VEC3: itemSize is 3, elementBytes is 4, itemBytes is 12.
    final elementBytes = typedArray.getBytesPerElement() ?? 0;
    final itemBytes = elementBytes * itemSize;
    final byteOffset = accessorDef["byteOffset"] ?? 0;
    final int? byteStride = accessorDef["bufferView"] != null
        ? json["bufferViews"][accessorDef["bufferView"]]["byteStride"]
        : null;
    final normalized = accessorDef["normalized"] == true;
    dynamic array;
    dynamic bufferAttribute;

    // The buffer is not interleaved if the stride is the item size in bytes.
    if (byteStride != null && byteStride != itemBytes) {
      // Each "slice" of the buffer, as defined by 'count' elements of 'byteStride' bytes, gets its own InterleavedBuffer
      // This makes sure that IBA.count reflects accessor.count properly
      final ibSlice = (byteOffset / byteStride).floor();
      final ibCacheKey = 'InterleavedBuffer:${accessorDef["bufferView"]}:${accessorDef["componentType"]}:$ibSlice:${accessorDef["count"]}';
      dynamic ib = parser.cache.get(ibCacheKey);
      if (ib == null) {
        array = typedArray.view(
          bufferView, 
          ibSlice * byteStride,
          (accessorDef["count"] * byteStride) ~/ elementBytes
        );

        final int stride = byteStride ~/ elementBytes;
        int totalLen = array.length;
        if(array is Uint8List){
          ib = InterleavedBuffer(Uint8Array(totalLen).set(array.buffer.asUint8List()), 1);
        }
        else if(array is Int8List){
          ib = InterleavedBuffer(Int8Array(totalLen).set(array.buffer.asInt8List()), 1);
        }
        else{
          ib = InterleavedBuffer(Float32Array(totalLen).set(array.buffer.asFloat32List()), stride);
        }

        parser.cache.add(ibCacheKey, ib);
      }

      bufferAttribute = InterleavedBufferAttribute(ib, itemSize, (byteOffset % byteStride) ~/ elementBytes, normalized);
    } 
    else {
      if (bufferView == null) {
        array = typedArray.createList(accessorDef["count"] * itemSize);
      } 
      else {
        array = typedArray.view(bufferView, byteOffset, accessorDef["count"] * itemSize);
      }
      bufferAttribute = GLTypeData.createBufferAttribute(array, itemSize, normalized);
    }

    // https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#sparse-accessors
    if (accessorDef["sparse"] != null) {
      final itemSizeIndices = webglTypeSize["SCALAR"]!;
      final typedArrayIndices = GLTypeData(accessorDef["sparse"]["indices"]["componentType"]);

      final byteOffsetIndices = accessorDef["sparse"]["indices"]["byteOffset"] ?? 0;
      final byteOffsetValues = accessorDef["sparse"]["values"]["byteOffset"] ?? 0;

      final sparseIndices = typedArrayIndices.view(sparseIndicesBufferView,
          byteOffsetIndices, accessorDef["sparse"]["count"] * itemSizeIndices);
      final sparseValues = typedArray.view(sparseValuesBufferView,
          byteOffsetValues, accessorDef["sparse"]["count"] * itemSize);

      if (bufferView != null) {
        // Avoid modifying the original ArrayBuffer, if the bufferView wasn't initialized with zeroes.
        bufferAttribute = Float32BufferAttribute(bufferAttribute.array.clone(),
            bufferAttribute.itemSize, bufferAttribute.normalized);
      }

      for (int i = 0, il = sparseIndices.length; i < il; i++) {
        final index = sparseIndices[i];

        bufferAttribute.setX(index, sparseValues[i * itemSize]);
        if (itemSize >= 2){
          bufferAttribute.setY(index, sparseValues[i * itemSize + 1]);
        }
        if (itemSize >= 3){
          bufferAttribute.setZ(index, sparseValues[i * itemSize + 2]);
        }
        if (itemSize >= 4){
          bufferAttribute.setW(index, sparseValues[i * itemSize + 3]);
        }
        if (itemSize >= 5){
          throw ('THREE.GLTFLoader: Unsupported itemSize in sparse BufferAttribute.');
        }
      }
    }

    return bufferAttribute;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#textures
  /// @param {number} textureIndex
  /// @return {Promise<THREE.Texture>}
  ///
  Future<Texture?> loadTexture(textureIndex) async {
    final parser = this;
    Map<String, dynamic> json = this.json;
    final options = this.options;

    Map<String, dynamic> textureDef = json["textures"][textureIndex];
    final sourceIndex = textureDef["source"] ?? 0;
    final sourceDef = json["images"][sourceIndex];
    final textureExtensions = textureDef["extensions"] ?? {};

    dynamic loader;

    if (sourceDef["uri"] != null) {
      loader = (options["manager"] as LoadingManager).getHandler(sourceDef["uri"]);
    }

    loader ??= textureExtensions[gltfExtensions["MSFT_TEXTURE_DDS"]] != null
        ? parser.extensions[gltfExtensions["MSFT_TEXTURE_DDS"]]["ddsLoader"]
        : textureLoader;

    return loadTextureImage(textureIndex, sourceIndex, loader);
  }

  Future<Texture?> loadTextureImage(int textureIndex, int sourceIndex, TextureLoader loader) async {
    final parser = this;
    final json = this.json;
    final textureDef = json["textures"][textureIndex];
    final sourceDef = json["images"][sourceIndex];
    final cacheKey = '${(sourceDef["uri"] ?? sourceDef["bufferView"])}:${textureDef["sampler"]}';

    if (textureCache[cacheKey] != null) {
      // See https://github.com/mrdoob/three.js/issues/21559.
      return textureCache[cacheKey];
    }

    loader.flipY = false;
    Texture? texture = await loadImageSource(sourceIndex, loader);

    texture?.flipY = false;

    if (textureDef["name"] != null) texture?.name = textureDef["name"];

    final samplers = json["samplers"] ?? {};
    Map sampler = samplers[textureDef["sampler"]] ?? {};

    texture?.magFilter = webglFilters[sampler["magFilter"]] ?? LinearFilter;
    texture?.minFilter = webglFilters[sampler["minFilter"]] ?? LinearMipmapLinearFilter;
    texture?.wrapS = webglWrappings[sampler["wrapS"]] ?? RepeatWrapping;
    texture?.wrapT = webglWrappings[sampler["wrapT"]] ?? RepeatWrapping;

    parser.associations[texture] = {"textures": textureIndex};

    textureCache[cacheKey] = texture;

    return texture;
  }

  Future<Texture?> loadImageSource(sourceIndex, TextureLoader loader) async {
    final parser = this;
    final json = this.json;
    final options = this.options;
    Texture? texture;

    if (sourceCache[sourceIndex] != null) {
      texture = sourceCache[sourceIndex];
      return texture!.clone();
    }

    Map sourceDef = json["images"][sourceIndex];
    String? sourceURI = sourceDef["uri"];

    if (sourceDef["bufferView"] != null) {
      final bufferView = await parser.getDependency('bufferView', sourceDef["bufferView"]);
      final blob = Blob(bufferView.asUint8List(), {"type": sourceDef["mimeType"]});
      texture = await loader.fromBlob(blob);
    }
    else if (sourceURI != null) {
      final String resolve = LoaderUtils.resolveURL(sourceURI, options["path"]);
      texture = await loader.unknown(resolve);
    } 
    else if (sourceURI == null) {
      throw ('GLTFLoader: Image $sourceIndex is missing URI and bufferView');
    }

    sourceCache[sourceIndex] = texture;
    return texture;
  }

  ///
  /// Asynchronously assigns a texture to the given material parameters.
  /// @param {Object} materialParams
  /// @param {string} mapName
  /// @param {Object} mapDef
  /// @return {Promise}
  ///
  Future<Texture?> assignTexture(materialParams, mapName, Map<String, dynamic> mapDef, [String? colorSpace]) async {
    final parser = this;

    Texture? texture = await getDependency('texture', mapDef["index"]);

    // Materials sample aoMap from UV set 1 and other maps from UV set 0 - this can't be configured
    // However, we will copy UV set 0 to UV set 1 on demand for aoMap
    if (mapDef["texCoord"] != null &&
        mapDef["texCoord"] != 0 &&
        !(mapName == 'aoMap' && mapDef["texCoord"] == 1)) {
      console.warning('GLTFLoader: Custom UV set ${mapDef["texCoord"]} for texture $mapName not yet supported.');
    }

    if (parser.extensions[gltfExtensions["KHR_TEXTURE_TRANSFORM"]] != null) {
      final transform = mapDef["extensions"] != null
          ? mapDef["extensions"][gltfExtensions["KHR_TEXTURE_TRANSFORM"]]
          : null;

      if (transform != null) {
        final gltfReference = parser.associations[texture];
        texture = parser.extensions[gltfExtensions["KHR_TEXTURE_TRANSFORM"]].extendTexture(texture, transform);
        parser.associations[texture] = gltfReference;
      }
    }


    if ( colorSpace != null ) {
      texture?.colorSpace = colorSpace;
    }

    materialParams[mapName] = texture;

    return texture;
  }

  ///
  /// Assigns final material to a Mesh, Line, or Points instance. The instance
  /// already has a material (generated from the glTF material options alone)
  /// but reuse of the same glTF material may require multiple threejs materials
  /// to accomodate different primitive types, defines, etc. New materials will
  /// be created if necessary, and reused from a cache.
  /// @param  {Object3D} mesh Mesh, Line, or Points instance.
  ///
  void assignFinalMaterial(Object3D mesh) {
    final geometry = mesh.geometry;
    Material material = mesh.material!;

    bool useVertexTangents = geometry?.attributes["tangent"] != null;
    bool useVertexColors = geometry?.attributes["color"] != null;
    bool useFlatShading = geometry?.attributes["normal"] == null;

    if (mesh is Points) {
      final cacheKey = 'PointsMaterial:${material.uuid}';

      PointsMaterial? pointsMaterial = cache.get(cacheKey);

      if (pointsMaterial == null) {
        pointsMaterial = PointsMaterial();
        pointsMaterial.copy(material);
        pointsMaterial.color.setFrom(material.color);
        pointsMaterial.map = material.map;
        pointsMaterial.sizeAttenuation = false; // glTF spec says points should be 1px

        cache.add(cacheKey, pointsMaterial);
      }

      material = pointsMaterial;
    } 
    else if (mesh is Line) {
      final cacheKey = 'LineBasicMaterial:${material.uuid}';

      LineBasicMaterial? lineMaterial = cache.get(cacheKey);

      if (lineMaterial == null) {
        lineMaterial = LineBasicMaterial();
        lineMaterial.copy(material);
        lineMaterial.color.setFrom(material.color);

        cache.add(cacheKey, lineMaterial);
      }

      material = lineMaterial;
    }

    // Clone the material if it will be modified
    if (useVertexTangents || useVertexColors || useFlatShading) {
      String cacheKey = 'ClonedMaterial:${material.uuid}:';

      if (material.type == "GLTFSpecularGlossinessMaterial"){
        cacheKey += 'specular-glossiness:';
      }
      if (useVertexTangents) cacheKey += 'vertex-tangents:';
      if (useVertexColors) cacheKey += 'vertex-colors:';
      if (useFlatShading) cacheKey += 'flat-shading:';

      Material? cachedMaterial = cache.get(cacheKey);

      if (cachedMaterial == null) {
        cachedMaterial = material.clone();

        if (useVertexTangents) cachedMaterial.vertexTangents = true;
        if (useVertexColors) cachedMaterial.vertexColors = true;
        if (useFlatShading) cachedMaterial.flatShading = true;

        cache.add(cacheKey, cachedMaterial);

        associations[cachedMaterial] = associations[material];
      }

      material = cachedMaterial;
    }

    // workarounds for mesh and geometry

    if (material.aoMap != null &&
        geometry?.attributes["uv2"] == null &&
        geometry?.attributes["uv"] != null) {
      geometry?.setAttributeFromString('uv2', geometry.attributes["uv"]);
    }

    // https://github.com/mrdoob/three.js/issues/11438#issuecomment-507003995
    if (material.normalScale != null && !useVertexTangents) {
      material.normalScale!.y = -material.normalScale!.y;
    }

    if (material.clearcoatNormalScale != null && !useVertexTangents) {
      material.clearcoatNormalScale!.y = -material.clearcoatNormalScale!.y;
    }

    mesh.material = material;
  }

  Type getMaterialType(int materialIndex) {
    return MeshStandardMaterial;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#materials
  /// @param {number} materialIndex
  /// @return {Promise<Material>}
  ///
  Future<Material> loadMaterial(materialIndex) async {
    final parser = this;
    final json = this.json;
    final extensions = this.extensions;
    Map<String, dynamic> materialDef = json["materials"][materialIndex];

    dynamic materialType;
    Map<String, dynamic> materialParams = {};
    Map<String, dynamic> materialExtensions = materialDef["extensions"] ?? {};

    List pending = [];

    if (materialExtensions[gltfExtensions["KHR_MATERIALS_PBR_SPECULAR_GLOSSINESS"]] != null) {
      final sgExtension = extensions[gltfExtensions["KHR_MATERIALS_PBR_SPECULAR_GLOSSINESS"]];
      materialType = sgExtension.getMaterialType(materialIndex);
      pending.add(sgExtension.extendParams(materialParams, materialDef, parser));
    } 
    else if (materialExtensions[gltfExtensions["KHR_MATERIALS_UNLIT"]] != null) {
      final kmuExtension = extensions[gltfExtensions["KHR_MATERIALS_UNLIT"]];
      materialType = kmuExtension.getMaterialType(materialIndex);
      pending.add(kmuExtension.extendParams(materialParams, materialDef, parser));
    } 
    else {
      // Specification:
      // https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#metallic-roughness-material

      Map<String, dynamic> metallicRoughness =
          materialDef["pbrMetallicRoughness"] ?? {};

      materialParams["color"] = Color(1.0, 1.0, 1.0);
      materialParams["opacity"] = 1.0;

      if (metallicRoughness["baseColorFactor"] is List) {
        List<double> array = List<double>.from(metallicRoughness["baseColorFactor"].map((e) => e.toDouble()));

        (materialParams["color"] as Color).setRGB( array[0], array[1], array[2]);
        materialParams["opacity"] = array[3];
      }

      if (metallicRoughness["baseColorTexture"] != null) {
        pending.add(await parser.assignTexture(materialParams, 'map', metallicRoughness["baseColorTexture"], SRGBColorSpace));
      }

      materialParams["metalness"] = metallicRoughness["metallicFactor"] ?? 1.0;
      materialParams["roughness"] = metallicRoughness["roughnessFactor"] ?? 1.0;

      if (metallicRoughness["metallicRoughnessTexture"] != null) {
        pending.add(await parser.assignTexture(materialParams, 'metalnessMap',
            metallicRoughness["metallicRoughnessTexture"]));
        pending.add(await parser.assignTexture(materialParams, 'roughnessMap',
            metallicRoughness["metallicRoughnessTexture"]));
      }

      materialType = await _invokeOne((ext) async {
        return ext?.getMaterialType != null
            ? await ext?.getMaterialType?.call(materialIndex)
            : null;
      });

      final v = await _invokeAll((ext) {
        return ext?.extendMaterialParams != null &&
            ext?.extendMaterialParams?.call(materialIndex, materialParams) != null;
      });

      pending.add(v);
    }

    if (materialDef["doubleSided"] == true) {
      materialParams["side"] = DoubleSide;
    }

    final alphaMode = materialDef["alphaMode"] ?? gltfAlphaModes["OPAQUE"];

    if (alphaMode == gltfAlphaModes["BLEND"]) {
      materialParams["transparent"] = true;

      // See: https://github.com/mrdoob/three.js/issues/17706
      materialParams["depthWrite"] = false;
    } 
    else {
      materialParams["transparent"] = false;

      if (alphaMode == gltfAlphaModes["MASK"]) {
        materialParams["alphaTest"] = materialDef["alphaCutoff"] ?? 0.5;
      }
    }

    if (materialDef["normalTexture"] != null &&
        materialType != MeshBasicMaterial) {
      pending.add(await parser.assignTexture(
          materialParams, 'normalMap', materialDef["normalTexture"]));

      if (materialDef["normalTexture"]["scale"] != null) {
        materialParams["normalScale"] = Vector2(
            materialDef["normalTexture"]["scale"],
            materialDef["normalTexture"]["scale"]);
      }
    }

    if (materialDef["occlusionTexture"] != null &&
        materialType != MeshBasicMaterial) {
      pending.add(await parser.assignTexture(
          materialParams, 'aoMap', materialDef["occlusionTexture"]));

      if (materialDef["occlusionTexture"]["strength"] != null) {
        materialParams["aoMapIntensity"] =
            materialDef["occlusionTexture"]["strength"];
      }
    }

    if (materialDef["emissiveFactor"] != null &&materialType != MeshBasicMaterial) {
      final emissiveFactor = List<double>.from(materialDef["emissiveFactor"].map((e) => e.toDouble()));
      materialParams["emissive"] = new Color().setRGB( emissiveFactor[0], emissiveFactor[1], emissiveFactor[2]);
    }

    if (materialDef["emissiveTexture"] != null &&
        materialType != MeshBasicMaterial
    ) {
      pending.add(await parser.assignTexture(materialParams, 'emissiveMap', materialDef["emissiveTexture"], SRGBColorSpace));
    }

    // await Future.wait(pending);

    late Material material;

    if (materialType == GLTFMeshStandardSGMaterial) {
      material = extensions[gltfExtensions["KHR_MATERIALS_PBR_SPECULAR_GLOSSINESS"]].createMaterial(materialParams);
    } else {
      material = createMaterialType(materialType, materialParams);
    }

    if (materialDef["name"] != null) material.name = materialDef["name"];

    assignExtrasToUserData(material, materialDef);

    parser.associations[material] = {
      "type": 'materials',
      "index": materialIndex,
      "materials": materialIndex
    };

    if (materialDef["extensions"] != null){
      addUnknownExtensionsToUserData(extensions, material, materialDef);
    }

    return material;
  }

  Material createMaterialType(materialType, Map<String, dynamic> materialParams) {
    if (materialType == GLTFMeshStandardSGMaterial) {
      return GLTFMeshStandardSGMaterial(materialParams);
    } else if (materialType == MeshBasicMaterial) {
      return MeshBasicMaterial.fromMap(materialParams);
    } else if (materialType == MeshPhysicalMaterial) {
      return MeshPhysicalMaterial.fromMap(materialParams);
    } else if (materialType == MeshStandardMaterial) {
      return MeshStandardMaterial.fromMap(materialParams);
    } else {
      throw ("GLTFParser createMaterialType materialType: ${materialType.runtimeType.toString()} is not support ");
    }
  }

  /// When Object3D instances are targeted by animation, they need unique names.
  String createUniqueName(String? originalName) {
    final sanitizedName = PropertyBinding.sanitizeNodeName(originalName ?? '');

    String name = sanitizedName;

    for (int i = 1; nodeNamesUsed[name] != null; ++i) {
      name = '${sanitizedName}_$i';
    }

    nodeNamesUsed[name] = true;

    return name;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#geometry
  ///
  /// Creates BufferGeometries from primitives.
  ///
  /// @param {Array<GLTF.Primitive>} primitives
  /// @return {Promise<Array<BufferGeometry>>}
  ///
  Future<List<BufferGeometry>> loadGeometries(primitives) async {
    final parser = this;
    final extensions = this.extensions;
    final cache = primitiveCache;

    createDracoPrimitive(primitive) async {
      final geometry = await extensions[gltfExtensions["KHR_DRACO_MESH_COMPRESSION"]]
          .decodePrimitive(primitive, parser);
      return await addPrimitiveAttributes(geometry, primitive, parser);
    }

    List<BufferGeometry> pending = [];

    for (int i = 0, il = primitives.length; i < il; i++) {
      Map<String, dynamic> primitive = primitives[i];
      final cacheKey = createPrimitiveKey(primitive);

      // See if we've already created this geometry
      final cached = cache[cacheKey];

      if (cached != null) {
        // Use the cached geometry if it exists
        pending.add(cached.promise);
      } 
      else {
        dynamic geometryPromise;

        if (primitive["extensions"] != null && primitive["extensions"][gltfExtensions["KHR_DRACO_MESH_COMPRESSION"]] != null) {
          // Use DRACO geometry if available
          geometryPromise = await createDracoPrimitive(primitive);
        } 
        else {
          // Otherwise create a geometry
          geometryPromise = await addPrimitiveAttributes(BufferGeometry(), primitive, parser);
        }

        // Cache this geometry
        cache[cacheKey] = {"primitive": primitive, "promise": geometryPromise};
        pending.add(geometryPromise);
      }
    }

    return pending;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#meshes
  /// @param {number} meshIndex
  /// @return {Promise<Group|Mesh|SkinnedMesh>}
  ///
  Future<Object3D> loadMesh(int meshIndex) async {
    final parser = this;
    final json = this.json;
    final extensions = this.extensions;

    Map<String, dynamic> meshDef = json["meshes"][meshIndex];
    final primitives = meshDef["primitives"];

    List<Future> pending = [];

    for (int i = 0, il = primitives.length; i < il; i++) {
      final material = primitives[i]["material"] == null
          ? createDefaultMaterial(cache)
          : await getDependency('material', primitives[i]["material"]);

      pending.add(Future.sync(() => material));
    }

    pending.add(parser.loadGeometries(primitives));

    final results = await Future.wait(pending);

    final materials = results.sublist(0, results.length - 1);
    final geometries = results[results.length - 1];

    final meshes = [];

    for (int i = 0, il = geometries.length; i < il; i++) {
      final geometry = geometries[i];
      Map<String, dynamic> primitive = primitives[i];

      // 1. create Mesh

      late Object3D mesh;
      final material = materials[i];

      if (
        primitive["mode"] == webglConstants["TRIANGLES"] ||
        primitive["mode"] == webglConstants["TRIANGLE_STRIP"] ||
        primitive["mode"] == webglConstants["TRIANGLE_FAN"] ||
        primitive["mode"] == null
      ) {
        // .isSkinnedMesh isn't in glTF spec. See ._markDefs()
        mesh = meshDef["isSkinnedMesh"] == true? SkinnedMesh(geometry, material): Mesh(geometry, material);

        if (mesh is SkinnedMesh ) {//&& !mesh.geometry!.attributes["skinWeight"].normalized
          // we normalize floating point skin weight array to fix malformed assets (see #15319)
          // it's important to skip this for non-float32 data since normalizeSkinWeights assumes non-normalized inputs
          mesh.normalizeSkinWeights();
        }

        if (primitive["mode"] == webglConstants["TRIANGLE_STRIP"]) {
          mesh.geometry = toTrianglesDrawMode(mesh.geometry, TriangleStripDrawMode);
        } 
        else if (primitive["mode"] == webglConstants["TRIANGLE_FAN"]) {
          mesh.geometry = toTrianglesDrawMode(mesh.geometry, TriangleFanDrawMode);
        }
      } 
      else if (primitive["mode"] == webglConstants["LINES"]) {
        mesh = LineSegments(geometry, material);
      } 
      else if (primitive["mode"] == webglConstants["LINE_STRIP"]) {
        mesh = Line(geometry, material);
      } 
      else if (primitive["mode"] == webglConstants["LINE_LOOP"]) {
        mesh = LineLoop(geometry, material);
      } 
      else if (primitive["mode"] == webglConstants["POINTS"]) {
        mesh = Points(geometry, material);
      } 
      else {
        throw ('THREE.GLTFLoader: Primitive mode unsupported: ${primitive["mode"]}');
      }

      if (mesh.geometry!.morphAttributes.keys.isNotEmpty) {
        updateMorphTargets(mesh, meshDef);
      }

      mesh.name = parser.createUniqueName(meshDef["name"] ?? ('mesh_$meshIndex'));
      assignExtrasToUserData(mesh, meshDef);

      if (primitive["extensions"] != null){
        addUnknownExtensionsToUserData(extensions, mesh, primitive);
      }

      parser.assignFinalMaterial(mesh);
      meshes.add(mesh);
    }
    
			for (int i = 0, il = meshes.length; i < il; i ++ ) {
				parser.associations[meshes[ i ]] = {
					'meshes': meshIndex,
					'primitives': i
				};
			}

    if (meshes.length == 1) {
      return meshes[0];
    }

    final group = Group();
    for (int i = 0; i < meshes.length; i++) {
      group.add(meshes[i]);
    }

    return group;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#cameras
  /// @param {number} cameraIndex
  /// @return {Promise<Camera>}
  ///
  Camera? loadCamera(cameraIndex) {
    Camera? camera;
    Map<String, dynamic> cameraDef = json["cameras"][cameraIndex];
    final params = cameraDef[cameraDef["type"]];

    if (params == null) {
      console.warning('GLTFLoader: Missing camera parameters.');
      return null;
    }

    if (cameraDef["type"] == 'perspective') {
      camera = PerspectiveCamera(
        (params["yfov"].toDouble() as double).toDeg(),
        params["aspectRatio"]?.toDouble() ?? 1.0,
        params["znear"]?.toDouble() ?? 1.0,
        params["zfar"]?.toDouble() ?? 2e6*1.0
      );
    } else if (cameraDef["type"] == 'orthographic') {
      camera = OrthographicCamera(
        params["xmag"] == null?-1.0:-params["xmag"]?.toDouble(), 
        params["xmag"]?.toDouble(),
        params["ymag"]?.toDouble(), 
        params["ymag"] == null?-1.0:-params["ymag"]?.toDouble(), 
        params["znear"]?.toDouble(), 
        params["zfar"]?.toDouble()
      );
    }

    if (cameraDef["name"] != null){
      camera?.name = createUniqueName(cameraDef["name"]);
    }

    assignExtrasToUserData(camera, cameraDef);

    return camera;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#skins
  /// @param {number} skinIndex
  /// @return {Promise<Object>}
  ///
  Future loadSkin_new(skinIndex) async {
		final skinDef = this.json['skins'][ skinIndex ];
		final pending = [];

		for (int i = 0, il = skinDef['joints'].length; i < il; i ++ ) {
			pending.add( await loadNodeShallow( skinDef['joints'][ i ] ) );
		}

		if ( skinDef['inverseBindMatrices'] != null ) {
			pending.add( await getDependency( 'accessor', skinDef['inverseBindMatrices'] ) );
		} else {
			pending.add( null );
		}

    final inverseBindMatrices = pending.removeLast();
    final jointNodes = pending;

    // Note that bones (joint nodes) may or may not be in the
    // scene graph at this time.

    final List<Bone> bones = [];
    final List<Matrix4> boneInverses = [];

    for (int i = 0, il = jointNodes.length; i < il; i ++ ) {
      final jointNode = jointNodes[ i ];

      if ( jointNode != null) {
        bones.add( jointNode );

        final mat = Matrix4.identity();

        if ( inverseBindMatrices != null ) {
          mat.copyFromUnknown( inverseBindMatrices.array, i * 16 );
        }

        boneInverses.add( mat );
      } 
      else {
        console.warning( 'THREE.GLTFLoader: Joint "%s" could not be found. ${skinDef['joints'][ i ]}', );
      }
    }

    return Skeleton( bones, boneInverses );
  }
  loadSkin(skinIndex) async {
    final skinDef = json["skins"][skinIndex];

    final skinEntry = {"joints": skinDef["joints"]};

    if (skinDef["inverseBindMatrices"] == null) {
      return skinEntry;
    }

    final accessor = await getDependency('accessor', skinDef["inverseBindMatrices"]);

    skinEntry["inverseBindMatrices"] = accessor;
    return skinEntry;
  }
  ///
  /// Specification: https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#animations
  /// @param {number} animationIndex
  /// @return {Promise<AnimationClip>}
  ///
  Future<AnimationClip> loadAnimation(animationIndex) async {
    final json = this.json;

    Map<String, dynamic> animationDef = json["animations"][animationIndex];

    List<Future> pendingNodes = [];
    List<Future> pendingInputAccessors = [];
    List<Future> pendingOutputAccessors = [];
    List<Future> pendingSamplers = [];
    List<Future> pendingTargets = [];

    for (int i = 0, il = animationDef["channels"].length; i < il; i++) {
      Map<String, dynamic> channel = animationDef["channels"][i];
      Map<String, dynamic> sampler =
          animationDef["samplers"][channel["sampler"]];
      Map<String, dynamic> target = channel["target"];
      final name = target["node"] ?? target["id"]; // NOTE: target.id is deprecated.
      final input = animationDef["parameters"] != null
          ? animationDef["parameters"][sampler["input"]]
          : sampler["input"];
      final output = animationDef["parameters"] != null
          ? animationDef["parameters"][sampler["output"]]
          : sampler["output"];

      pendingNodes.add(getDependency('node', name));
      pendingInputAccessors.add(getDependency('accessor', input));
      pendingOutputAccessors.add(getDependency('accessor', output));
      pendingSamplers.add(Future.sync(() => sampler));
      pendingTargets.add(Future.sync(() => target));
    }

    final dependencies = await Future.wait([
      Future.wait(pendingNodes),
      Future.wait(pendingInputAccessors),
      Future.wait(pendingOutputAccessors),
      Future.wait(pendingSamplers),
      Future.wait(pendingTargets)
    ]);

    final nodes = dependencies[0];
    final inputAccessors = dependencies[1];
    final outputAccessors = dependencies[2];
    final samplers = dependencies[3];
    final targets = dependencies[4];

    List<KeyframeTrack> tracks = [];

    for (int i = 0, il = nodes.length; i < il; i++) {
      final node = nodes[i];
      final inputAccessor = inputAccessors[i];

      final outputAccessor = outputAccessors[i];
      Map<String, dynamic> sampler = samplers[i];
      Map<String, dynamic> target = targets[i];

      if (node == null) continue;

      node.updateMatrix();
      node.matrixAutoUpdate = true;

      final typedKeyframeTrack = _TypedKeyframeTrack(PathProperties.getValue(target["path"]));

      String targetName = node.name ?? node.uuid;

      final interpolation = sampler["interpolation"] != null
          ? gltfInterpolation[sampler["interpolation"]]
          : InterpolateLinear;

      final targetNames = [];

      if (PathProperties.getValue(target["path"]) == PathProperties.weights) {
        // Node may be a Group (glTF mesh with several primitives) or a Mesh.
        node.traverse((object) {
          if (object.morphTargetInfluences != null) {
            targetNames.add(object.name ?? object.uuid);
          }
        });
      } else {
        targetNames.add(targetName);
      }

      dynamic outputArray = outputAccessor.array.toDartList();

      if (outputAccessor.normalized) {
        final scale = getNormalizedComponentScale(outputArray.runtimeType);

        final scaled = Float32List(outputArray.length);

        for (int j = 0, jl = outputArray.length; j < jl; j++) {
          scaled[j] = outputArray[j] * scale;
        }

        outputArray = scaled;
      }

      for (int j = 0, jl = targetNames.length; j < jl; j++) {
        final track = typedKeyframeTrack.createTrack(
            targetNames[j] + '.' + PathProperties.getValue(target["path"]),
            inputAccessor.array.toDartList(),
            outputArray,
            interpolation);

        // Override interpolation with custom factory method.
        if (sampler["interpolation"] == 'CUBICSPLINE') {
          track.createInterpolant = (result) {
            // A CUBICSPLINE keyframe in glTF has three output values for each input value,
            // representing inTangent, splineVertex, and outTangent. As a result, track.getValueSize()
            // must be divided by three to get the interpolant's sampleSize argument.
            return GLTFCubicSplineInterpolant(
                track.times, track.values, track.getValueSize() ~/ 3, result);
          };

          // Mark as CUBICSPLINE. `track.getInterpolation()` doesn't support custom interpolants.
          // track.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline = true;
          console.info("GLTFParser.loadAnimation isInterpolantFactoryMethodGLTFCubicSpline TODO ?? how to handle this case ??? ");
        }

        tracks.add(track);
      }
    }

    final name = animationDef["name"] ?? 'animation_$animationIndex';

    return AnimationClip(name, -1, tracks);
  }

  Future<Object3D?> createNodeMesh(int nodeIndex) async {
    final json = this.json;
    final parser = this;
    Map<String, dynamic> nodeDef = json["nodes"][nodeIndex];

    if (nodeDef["mesh"] == null) return null;

    final mesh = await parser.getDependency('mesh', nodeDef["mesh"]);

    final node = parser.getNodeRef(parser.meshCache, nodeDef["mesh"], mesh);

    // if weights are provided on the node, override weights on the mesh.
    if (nodeDef["weights"] != null) {
      node.traverse((o) {
        if (o is! Mesh) return;//!o.isMesh
        for (int i = 0, il = nodeDef["weights"].length; i < il; i++) {
          o.morphTargetInfluences[i] = nodeDef["weights"][i];
        }
      });
    }

    return node;
  }

  Future<Object3D> loadNode(int nodeIndex) async {
    return await loadNodeShallow( nodeIndex );
		// final json = this.json;
		// final parser = this;

		// final nodeDef = json['nodes'][ nodeIndex ];

		// final nodePending = await loadNodeShallow( nodeIndex );

		// final List<Object3D> childPending = [];
		// final childrenDef = nodeDef['children'] ?? [];

		// for (int i = 0, il = childrenDef.length; i < il; i ++ ) {
		// 	childPending.add( await parser.getDependency( 'node', childrenDef[ i ] ) );
		// }
		// final skeletonPending = nodeDef['skin'] == null? null : await parser.getDependency( 'skin', nodeDef['skin'] );
    
    // if ( skeletonPending != null ) {
    //   // This full traverse should be fine because
    //   // child glTF nodes have not been added to this node yet.
    //   nodePending.traverse(( mesh ) {
    //     if (mesh is! SkinnedMesh ) return;
    //     mesh.bind( skeletonPending, Matrix4.identity() );
    //   } );

    // }

    // for ( int i = 0, il = childPending.length; i < il; i ++ ) {
    //   nodePending.add( childPending[ i ] );
    // }

    // return nodePending;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#nodes-and-hierarchy
  /// @param {number} nodeIndex
  /// @return {Promise<Object3D>}
  ///
  Future<Object3D> loadNodeShallow(int nodeIndex) async {
    final json = this.json;
    final extensions = this.extensions;

    Map<String, dynamic> nodeDef = json["nodes"][nodeIndex];

    // reserve node's name before its dependencies, so the root has the intended name.
    final nodeName = nodeDef["name"] != null ? createUniqueName(nodeDef["name"]) : '';

    final pending = [];

    final meshPromise = await _invokeOne((ext) {
      return ext?.createNodeMesh != null ? ext!.createNodeMesh(nodeIndex) : null;
    });

    if (meshPromise != null) {
      pending.add(meshPromise);
    }

    if (nodeDef["camera"] != null) {
      final camera = await getDependency('camera', nodeDef["camera"]);

      pending.add(await getNodeRef(cameraCache, nodeDef["camera"], camera));
    }

    List results = await _invokeAll((ext) async {
      return ext?.createNodeAttachment != null
          ? await ext?.createNodeAttachment?.call(nodeIndex)
          : null;
    });

    final objects = [];

    //pending.forEach((element) {
    for(final element in pending){
      objects.add(element);
    }

    //results.forEach((element) {
    for(final element in results){
      objects.add(element);
    }

    late final Object3D node;
    // .isBone isn't in glTF spec. See ._markDefs
    if (nodeDef["isBone"] == true) {
      node = Bone();
    } 
    else if (objects.length > 1) {
      node = Group();
    } 
    else if (objects.length == 1) {
      node = objects[0];
    } 
    else {
      node = Object3D();
    }

    if (objects.isEmpty || node != objects[0]) {
      for (int i = 0; i < objects.length; i++) {
        node.add(objects[i]);
      }
    }

    if (nodeDef["name"] != null) {
      node.userData["name"] = nodeDef["name"];
      node.name = nodeName;
    }

    assignExtrasToUserData(node, nodeDef);

    if (nodeDef["extensions"] != null){
      addUnknownExtensionsToUserData(extensions, node, nodeDef);
    }

    if (nodeDef["matrix"] != null) {
      final matrix = Matrix4();
      matrix.copyFromUnknown(List<num>.from(nodeDef["matrix"]));
      node.applyMatrix4(matrix);
    } else {
      if (nodeDef["translation"] != null) {
        node.position.copyFromUnknown(List<num>.from(nodeDef["translation"]));
      }

      if (nodeDef["rotation"] != null) {
        node.quaternion.fromNumArray(List<num>.from(nodeDef["rotation"]));
      }

      if (nodeDef["scale"] != null) {
        node.scale.copyFromUnknown(List<num>.from(nodeDef["scale"]));
      }
    }

    associations[node] = {"type": 'nodes', "index": nodeIndex};
    return node;
  }

  ///
  /// Specification: https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#scenes
  /// @param {number} sceneIndex
  /// @return {Promise<Group>}
  ///
  Future<void> buildNodeHierarchy(int nodeId, Object3D? parentObject, Map<String,dynamic> json) async {
    Map<String, dynamic> nodeDef = json["nodes"][nodeId];

    final Object3D? node = await getDependency('node', nodeId);

    if (nodeDef["skin"] != null) {
      dynamic skinEntry;

      final skin = await getDependency('skin', nodeDef["skin"]);
      skinEntry = skin;

      final jointNodes = [];

      for (int i = 0; i < skinEntry["joints"].length; i++) {
        final node1 = await getDependency('node', skinEntry["joints"][i]);
        jointNodes.add(node1);
      }

      node?.traverse((mesh) {
        if(mesh is SkinnedMesh) {
          List<Bone> bones = [];
          List<Matrix4> boneInverses = [];
          mesh.frustumCulled = false;

          for (int j = 0, jl = jointNodes.length; j < jl; j++) {
            final jointNode = jointNodes[j];

            if (jointNode != null) {
              bones.add(jointNode);

              final mat = Matrix4();

              if (skinEntry["inverseBindMatrices"] != null) {
                mat.copyFromUnknown(skinEntry["inverseBindMatrices"].array, j * 16);
              }

              boneInverses.add(mat);
            } else {
              console.warning('GLTFLoader: Joint "%s" could not be found. ${skinEntry["joints"][j]}');
            }
          }

          mesh.bind(Skeleton(bones, boneInverses),mesh.matrixWorld);
        }
      });
    }

    // build node hierachy
    parentObject?.add(node);

    if (nodeDef["children"] != null) {
      final List children = nodeDef["children"];
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        await buildNodeHierarchy(child, node, json);
      }
    }
  }

  Future<Group> loadScene(int sceneIndex) async {
    final json = this.json;
    final extensions = this.extensions;
    Map<String, dynamic> sceneDef = this.json["scenes"][sceneIndex];

    // Loader returns Group, not Scene.
    // See: https://github.com/mrdoob/three.js/issues/18342#issuecomment-578981172
    final scene = Group();
    if (sceneDef["name"] != null){
      scene.name = createUniqueName(sceneDef["name"]);
    }

    assignExtrasToUserData(scene, sceneDef);

    if (sceneDef["extensions"] != null){
      addUnknownExtensionsToUserData(extensions, scene, sceneDef);
    }

    final List nodeIds = sceneDef["nodes"] ?? [];

    for (int i = 0; i < nodeIds.length; i++) {
      await buildNodeHierarchy(nodeIds[i], scene, json);
    }

    return scene;
  }

	Future loadScene_new(int sceneIndex ) async{
		final extensions = this.extensions;
		final sceneDef = this.json['scenes'][ sceneIndex ] as Map;

		// Loader returns Group, not Scene.
		// See: https://github.com/mrdoob/three.js/issues/18342#issuecomment-578981172
		final scene = new Group();

		if ( sceneDef['name'] != null) scene.name = createUniqueName( sceneDef['name'] );
		assignExtrasToUserData( scene, sceneDef );

		if ( sceneDef['extensions'] != null) addUnknownExtensionsToUserData( extensions, scene, sceneDef );
		final nodeIds = sceneDef['nodes'] ?? [];
		final pending = [];

		for (int i = 0, il = nodeIds.length; i < il; i ++ ) {
			pending.add( await getDependency( 'node', nodeIds[ i ] ) );
		}

    for ( int i = 0, il = pending.length; i < il; i ++ ) {
      scene.add( pending[ i ] );
    }

    // Removes dangling associations, associations that reference a node that
    // didn't make it into the scene.
    final reduceAssociations = ( node ){
      final reducedAssociations = new Map();
      for ( final key in associations.keys) {
        if ( key is Material || key is Texture ) {
          reducedAssociations[key] =  associations[key];
        }
      }

      node.traverse(( node ){
        final mappings = parser.associations[node];
        if ( mappings != null ) {
          reducedAssociations[node] =  mappings;
        }
      } );

      return reducedAssociations;
    };

    parser.associations = reduceAssociations( scene );

    return scene;
	}
}

//class GLTFParser end...

class _TypedKeyframeTrack {
  late String path;

  _TypedKeyframeTrack(this.path);

  KeyframeTrack createTrack(String v0, List<num> v1, List<num> v2, v3) {
    switch (path) {
      case PathProperties.weights:
        return NumberKeyframeTrack(v0, v1, v2, v3);
      case PathProperties.rotation:
        return QuaternionKeyframeTrack(v0, v1, v2, v3);
      case PathProperties.position:
      case PathProperties.scale:
      default:
        return VectorKeyframeTrack(v0, v1, v2, v3);
    }
  }
}
