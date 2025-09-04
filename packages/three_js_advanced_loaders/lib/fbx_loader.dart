import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
//import 'package:archive/archive.dart';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_curves/three_js_curves.dart';

_FBXTree? _fbxTree;
Map? connections;
AnimationObject? sceneGraph;

class MorphBuffers{
  MorphBuffers({
    List<double>? vertex,
    List<double>? normal,
    List<double>? colors,
    List<List<double>>? uvs,
    List<int>? materialIndex,
    List<double>? vertexWeights,
    List<int>? weightsIndices,
  }){
    this.vertex = vertex ?? [];
    this.normal = normal ?? [];
    this.colors = colors ?? [];
    this.uvs = uvs ?? [];
    this.materialIndex = materialIndex ?? [];
    this.vertexWeights = vertexWeights ?? [];
    this.weightsIndices = weightsIndices ?? [];
  }

  List<double> vertex = [];
  List<double> normal = [];
  List<double> colors = [];
  List<List<double>> uvs  = [];
  List<int> materialIndex = [];
  List<num> vertexWeights = [];
  List<int> weightsIndices = [];

  @override
  String toString(){
    return {
      "vertex": vertex,
      "normal": normal,
      "colors": colors,
      "uvs": uvs,
      "materialIndex": materialIndex,
      "vertexWeights": vertexWeights,
      "weightsIndices": weightsIndices,
    }.toString();
  }
}

///
/// Loader loads FBX file and generates Group representing FBX scene.
/// Requires FBX file to be >= 7.0 and in ASCII or >= 6400 in Binary format
/// Versions lower than this may load but will probably have errors
///
/// Needs Support:
///  Morph normals / blend shape normals
///
/// FBX format references:
/// 	https://help.autodesk.com/view/FBX/2017/ENU/?guid=__cpp_ref_index_html (C++ SDK reference)
///
/// Binary format specification:
///	https://code.blender.org/2013/08/fbx-binary-file-format-specification/
///
class FBXLoader extends Loader {
  late int innerWidth;
  late int innerHeight;
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a new [FontLoader].
  FBXLoader({LoadingManager? manager, int width = 1, int height = 1}):super(manager){
    innerHeight = height;
    innerWidth = width;
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
    _fbxTree = null;
    connections = null;
    sceneGraph = null;
  }

  void _init(){
    _loader.setPath(path);
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<AnimationObject?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<AnimationObject?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  Future<AnimationObject> _parse(Uint8List bufferBytes) {
    if (_isFbxFormatBinary(bufferBytes)) {
      _fbxTree = _BinaryParser().parse(bufferBytes);
    } 
    else {
      final fbxText = _convertArrayBufferToString(bufferBytes);

      if (!_isFbxFormatASCII(fbxText)) {
        throw ('FBXLoader: Unknown format.');
      }

      if (_getFbxVersion(fbxText) < 7000) {
        throw ('FBXLoader: FBX version not supported, FileVersion: ${_getFbxVersion(fbxText)}');
      }

      _fbxTree = _TextParser().parse(fbxText);
    }

    TextureLoader textureLoader = TextureLoader(manager: manager)
        .setPath(this.resourcePath ?? path)//(resourcePath == '' || resourcePath == null) ? path : ''
        .setCrossOrigin(crossOrigin);

    return __FBXTreeParser(textureLoader, manager, innerWidth, innerHeight).parse();
  }

  @override
  FBXLoader setPath(String path) {
    super.setPath(path);
    return this;
  }
}

// Parse the _FBXTree object returned by the _BinaryParser or _TextParser and return a Group
class __FBXTreeParser {
  TextureLoader textureLoader;
  LoadingManager manager;

  int innerWidth;
  int innerHeight;

  __FBXTreeParser(this.textureLoader, this.manager, this.innerWidth, this.innerHeight);

  Future<AnimationObject> parse() async {
    connections = parseConnections();
    final images = parseImages();
    final textures = await parseTextures(images);
    final materials = parseMaterials(textures);
    final deformers = parseDeformers();
    final geometryMap = _GeometryParser().parse(deformers);

    parseScene(deformers, geometryMap, materials);

  return sceneGraph!;
  }

  // Parses _FBXTree.Connections which holds parent-child connections between objects (e.g. material -> texture, model->geometry )
  // and details the connection type
  Map parseConnections() {
    final Map connectionMap = {};

    if (_fbxTree?.connections != null) {
      final rawConnections = _fbxTree?.connections!["connections"];
      rawConnections.forEach((rawConnection) {
        final fromID = rawConnection[0];
        final toID = rawConnection[1];

        dynamic relationship;
        if (rawConnection.length > 2) {
          relationship = rawConnection[2];
        }

        if (!connectionMap.containsKey(fromID)) {
          connectionMap[fromID] = {"parents": [], "children": []};
        }

        final parentRelationship = {"ID": toID, "relationship": relationship};
        connectionMap[fromID]["parents"].add(parentRelationship);

        if (!connectionMap.containsKey(toID)) {
          connectionMap[toID] = {"parents": [], "children": []};
        }

        final childRelationship = {"ID": fromID, "relationship": relationship};
        connectionMap[toID]["children"].add(childRelationship);
      });
    }

    return connectionMap;
  }

  // Parse _FBXTree.Objects.Video for embedded image data
  // These images are connected to textures in _FBXTree.Objects.Textures
  // via _FBXTree.Connections.
  Map parseImages() {
    final Map images = {};
    final blobs = {};

    if (_fbxTree?.objects?["Video"] != null) {
      final videoNodes = _fbxTree?.objects!["Video"];

      for (final nodeID in videoNodes.keys) {
        final videoNode = videoNodes[nodeID];

        final id = _parseInt(nodeID);

        images[id] = videoNode["RelativeFilename"] ?? videoNode["Filename"];

        // raw image data is in videoNode.Content
        if (videoNode["Content"] != null) {
          // final arrayBufferContent = ( videoNode["Content"] is ArrayBuffer ) && ( videoNode["Content"].byteLength > 0 );
          final arrayBufferContent = (videoNode["Content"] is TypedData) &&
              (videoNode["Content"].byteLength > 0);
          final base64Content =
              (videoNode["Content"] is String) && (videoNode["Content"] != '');

          if (arrayBufferContent || base64Content) {
            final image = parseImage(videoNodes[nodeID]);

            blobs[videoNode.RelativeFilename ?? videoNode.Filename] = image;
          }
        }
      }
    }

    for (final id in images.keys) {
      final filename = images[id];

      if (blobs[filename] != null){
        images[id] = blobs[filename];
      }
      else{
        images[id] = images[id].split('\\').removeLast();
      }
    }

    return images;
  }

  // Parse embedded image data in _FBXTree.Video.Content
  String? parseImage(Map videoNode) {
    final content = videoNode['Content'];
    String fileName = videoNode['RelativeFilename'] ?? videoNode['Filename'];
    final extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();

    String type;

    switch (extension) {
      case 'bmp':
        type = 'image/bmp';
        break;

      case 'jpg':
      case 'jpeg':
        type = 'image/jpeg';
        break;

      case 'png':
        type = 'image/png';
        break;

      case 'tif':
        type = 'image/tiff';
        break;

      case 'tga':
        if (manager.getHandler('.tga') == null) {
          console.warning('FBXLoader: TGA loader not found, skipping $fileName');
        }

        type = 'image/tga';
        break;

      case 'dds':
        if (manager.getHandler('.dds') == null) {
          console.warning('FBXLoader: DDS loader not found, skipping $fileName');
        }

        type = 'image/dds';
        break;

			case 'webp':

				type = 'image/webp';
				break;

      default:
        console.warning('FBXLoader: Image type "$extension" is not supported.');
        return null;
    }

    if (content is String) {
      // ASCII format

      return 'data:$type;base64,$content';
    } else {
      // Binary Format

      final array = Uint8List(content);
      return createObjectURL(Blob([array], {'type': type}));
    }
  }

  // Parse nodes in _FBXTree.Objects.Texture
  // These contain details such as UV scaling, cropping, rotation etc and are connected
  // to images in _FBXTree.Objects.Video
  Future<Map<int,Texture>> parseTextures(Map images) async {
    final Map<int,Texture> textureMap = {};
    if (_fbxTree?.objects?["Texture"] != null) {
      final textureNodes = _fbxTree?.objects!["Texture"];
      for (final nodeID in textureNodes.keys) {
        final texture = await parseTexture(textureNodes[nodeID], images);
        if(texture != null)textureMap[_parseInt(nodeID)!] = texture;
      }
    }

    return textureMap;
  }

  // Parse individual node in _FBXTree.Objects.Texture
  Future<Texture?> parseTexture(Map textureNode, Map images) async {
    final Texture? texture = await loadTexture(textureNode, images);

    texture?.id = textureNode["id"];
    texture?.name = textureNode["attrName"];

    final wrapModeU = textureNode["WrapModeU"];
    final wrapModeV = textureNode["WrapModeV"];

    final valueU = wrapModeU != null ? wrapModeU.value : 0;
    final valueV = wrapModeV != null ? wrapModeV.value : 0;

    // http://download.autodesk.com/us/fbx/SDKdocs/FBX_SDK_Help/files/fbxsdkref/class_k_fbx_texture.html#889640e63e2e681259ea81061b85143a
    // 0: repeat(default), 1: clamp

    texture?.wrapS = valueU == 0 ? RepeatWrapping : ClampToEdgeWrapping;
    texture?.wrapT = valueV == 0 ? RepeatWrapping : ClampToEdgeWrapping;

    if (textureNode["Scaling"] != null) {
      final values = textureNode["Scaling"].value;
      texture?.repeat.x = values[0];
      texture?.repeat.y = values[1];
    }

		if (textureNode["Translation"] != null) {
			final values = textureNode['Translation'].value;
			texture?.offset.x = values[ 0 ];
			texture?.offset.y = values[ 1 ];
		}

    return texture;
  }

  // load a texture specified as a blob or data URI, or via an external URL using TextureLoader
  Future<Texture?> loadTexture(Map textureNode, Map images) async {
    String fileName = '';

    final currentPath = textureLoader.path;
    final children = connections?[textureNode["id"]]["children"];

    if (children != null && children.length > 0 && images[children[0]["ID"]] != null) {
      fileName = images[children[0]["ID"]];
      if (fileName.indexOf('blob:') == 0 || fileName.indexOf('data:') == 0) {
        textureLoader.setPath('');
      }else{
        fileName = fileName.split('/').last;
      }
    }

    Texture? texture;
    String nodeFileName = textureNode["FileName"];

    final extension = nodeFileName.substring(nodeFileName.length - 3).toLowerCase();

    if (extension == 'tga') {
      final loader = manager.getHandler('.tga');

      if (loader == null) {
        console.warning('FBXLoader: TGA loader not found, creating placeholder texture for ${textureNode["RelativeFilename"]}');
        texture = Texture();
      } 
      else {
        loader.setPath(textureLoader.path);
        final String resolve = manager.resolveURL(fileName);
        texture = (await loader.unknown(resolve)) as Texture?;
      }
    } 
    else if (extension == 'dds') {
      final loader = manager.getHandler('.dds');
      if (loader == null) {
        console.warning('FBXLoader: DDS loader not found, creating placeholder texture for ${textureNode["RelativeFilename"]}');
        texture = Texture();
      } 
      else {
        loader.setPath(textureLoader.path);
        final String resolve = manager.resolveURL(fileName);
        texture = (await loader.unknown(resolve)) as Texture;
      }
    }
    else if (extension == 'psd') {
      final loader = manager.getHandler('.psd');
      if (loader == null) {
        console.warning('FBXLoader: PSD textures are not supported, creating placeholder texture for ${textureNode["RelativeFilename"]}');
        texture = Texture();
      } 
      else {
        loader.setPath(textureLoader.path);
        final String resolve = manager.resolveURL(fileName);
        texture = (await loader.unknown(resolve)) as Texture?;
      }
    } 
    else {
      texture = (await textureLoader.unknown(fileName)) as Texture;
    }

    textureLoader.setPath(currentPath);
    return texture;
  }

  // Parse nodes in _FBXTree.Objects.Material
  Map<int?,Material> parseMaterials(Map textureMap) {
    final Map<int?,Material> materialMap = {};

    if (_fbxTree?.objects?["Material"] != null) {
      final materialNodes = _fbxTree?.objects!["Material"];

      for (final nodeID in materialNodes.keys) {
        final material = parseMaterial(materialNodes[nodeID], textureMap);

        if (material != null) materialMap[_parseInt(nodeID)] = material;
      }
    }

    return materialMap;
  }

  // Parse single node in _FBXTree.Objects.Material
  // Materials are connected to texture maps in _FBXTree.Objects.Textures
  // FBX format currently only supports Lambert and Phong shading models
  Material? parseMaterial(Map<String, dynamic> materialNode, Map textureMap) {
    final id_ = materialNode["id"];
    final name = materialNode["attrName"];
    dynamic type = materialNode["ShadingModel"];

    // Case where FBX wraps shading model in property object.
    if (type is! String) {
      type = type.runtimeType;
    }

    // Ignore unused materials which don't have any connections.
    if (connections?.containsKey(id_) == false) return null;

    Map<String,dynamic> parameters = parseParameters(materialNode, textureMap, id_);

    Material? material;

    switch (type.toLowerCase()) {
      case 'phong':
        material = MeshPhongMaterial();
        break;
      case 'lambert':
        material = MeshLambertMaterial();
        break;
      default:
        console.warning('FBXLoader: unknown material type "%s". Defaulting to MeshPhongMaterial.$type');
        material = MeshPhongMaterial();
        break;
    }

    material.setValuesFromString(parameters);
    material.name = name;

    return material;
  }

  // Parse FBX material and return parameters suitable for a three.js material
  // Also parse the texture map and return any textures associated with the material
  Map<String,dynamic> parseParameters(Map materialNode, Map textureMap, int id) {
    Map<String, dynamic> parameters = {};

    if (materialNode["BumpFactor"] != null) {
      parameters["bumpScale"] = materialNode["BumpFactor"]["value"];
    }

    if (materialNode["Diffuse"] != null) {
      parameters["color"] = Color.fromList(List<double>.from(materialNode["Diffuse"]["value"]));
    } 
    else if (materialNode["DiffuseColor"] != null && (materialNode["DiffuseColor"]["type"] == 'Color' || materialNode["DiffuseColor"]["type"] == 'ColorRGB')) {
      // The blender exporter exports diffuse here instead of in materialNode.Diffuse
      parameters["color"] = Color.fromList(List<double>.from(materialNode["DiffuseColor"]["value"]));
    }

    if (materialNode["DisplacementFactor"] != null) {
      parameters["displacementScale"] = materialNode["DisplacementFactor"]["value"];
    }

    if (materialNode["Emissive"] != null) {
      parameters["emissive"] = Color.fromList(List<double>.from(materialNode["Emissive"]["value"]));
    } 
    else if (materialNode["EmissiveColor"] != null &&
        (materialNode["EmissiveColor"]["type"] == 'Color' ||
            materialNode["EmissiveColor"].type == 'ColorRGB')) {
      // The blender exporter exports emissive color here instead of in materialNode.Emissive
      parameters["emissive"] = Color.fromList(List<double>.from(materialNode["EmissiveColor"]["value"]));
    }

    if (materialNode["EmissiveFactor"] != null) {
      parameters["emissiveIntensity"] = double.parse(materialNode["EmissiveFactor"]["value"].toString());
    }

    if (materialNode["Opacity"] != null) {
      parameters["opacity"] = double.parse(materialNode["Opacity"]["value"].toString());
    }

    if (parameters["opacity"] != null && parameters["opacity"] < 1.0) {
      parameters["transparent"] = true;
    }

    if (materialNode["ReflectionFactor"] != null) {
      parameters["reflectivity"] = double.parse(materialNode["ReflectionFactor"]["value"].toString());
    }

    if (materialNode["Shininess"] != null) {
      parameters["shininess"] = double.parse(materialNode["Shininess"]["value"].toString());
    }

    if (materialNode["Specular"] != null) {
      parameters["specular"] = Color.fromList(List<double>.from(materialNode["Specular"]["value"]));
    } 
    else if (materialNode["SpecularColor"] != null && materialNode["SpecularColor"]["type"] == 'Color') {
      // The blender exporter exports specular color here instead of in materialNode.Specular
      parameters["specular"] = Color.fromList(List<double>.from(materialNode["SpecularColor"]["value"]));
    }

    final scope = this;

    final connection = connections?[id];

    if (connection["children"] != null) {
      connection["children"].forEach((child) {
        final type = child["relationship"];

        final childID = child["ID"];

        switch (type) {
          case 'Bump':
            parameters["bumpMap"] = scope.getTexture(textureMap, childID);
            break;

          case 'Maya|TEX_ao_map':
            parameters["aoMap"] = scope.getTexture(textureMap, childID);
            break;

          case 'DiffuseColor':
          case 'Maya|TEX_color_map':
            parameters["map"] = scope.getTexture(textureMap, childID);
            if (parameters["map"] != null) {
              parameters["map"].colorSpace = SRGBColorSpace;
            }

            break;

          case 'DisplacementColor':
            parameters["displacementMap"] =
                scope.getTexture(textureMap, childID);
            break;

          case 'EmissiveColor':
            parameters["emissiveMap"] = scope.getTexture(textureMap, childID);
            if (parameters["emissiveMap"] != null) {
              parameters["emissiveMap"].colorSpace = SRGBColorSpace;
            }

            break;

          case 'NormalMap':
          case 'Maya|TEX_normal_map':
            parameters["normalMap"] = scope.getTexture(textureMap, childID);
            break;

          case 'ReflectionColor':
            parameters["envMap"] = scope.getTexture(textureMap, childID);
            if (parameters["envMap"] != null) {
              parameters["envMap"].mapping = EquirectangularReflectionMapping;
              parameters["envMap"].colorSpace = SRGBColorSpace;
            }

            break;

          case 'SpecularColor':
            parameters["specularMap"] = scope.getTexture(textureMap, childID);
            if (parameters["specularMap"] != null) {
              parameters["specularMap"].colorSpace = SRGBColorSpace;
            }

            break;

          case 'TransparentColor':
          case 'TransparencyFactor':
            parameters["alphaMap"] = scope.getTexture(textureMap, childID);
            parameters["transparent"] = true;
            break;

          case 'AmbientColor':
          case 'ShininessExponent': // AKA glossiness map
          case 'SpecularFactor': // AKA specularLevel
          case 'VectorDisplacementColor': // NOTE: Seems to be a copy of DisplacementColor
          default:
            console.warning('FBXLoader: %s map is not supported in three.js, skipping texture. $type');
            break;
        }
      });
    }

    return parameters;
  }

  // get a texture from the textureMap for use by a material.
  Texture? getTexture(Map textureMap, int id) {
    // if the texture is a layered texture, just use the first layer and issue a warning
    if (_fbxTree?.objects?["LayeredTexture"] != null &&
        _fbxTree?.objects?["LayeredTexture"].id != null) {
      console.warning('FBXLoader: layered textures are not supported in three.js. Discarding all but first layer.');
      id = connections?[id].children[0]['ID'];
    }

    return textureMap[id];
  }

  // Parse nodes in _FBXTree.Objects.Deformer
  // Deformer node can contain skinning or Vertex Cache animation data, however only skinning is supported here
  // Generates map of Skeleton-like objects for use later when generating and binding skeletons.
  Map parseDeformers() {
    Map skeletons = {};
    Map morphTargets = {};

    if (_fbxTree?.objects?["Deformer"] != null) {
      final deformerNodes = _fbxTree?.objects!["Deformer"];

      for (final nodeID in deformerNodes.keys) {
        Map deformerNode = deformerNodes[nodeID];

        final relationships = connections?[_parseInt(nodeID)];

        if (deformerNode["attrType"] == 'Skin') {
          final skeleton = parseSkeleton(relationships, deformerNodes);
          skeleton["ID"] = nodeID;

          if (relationships["parents"].length > 1){
            console.warning('FBXLoader: skeleton attached to more than one geometry is not supported.');
          }
          skeleton["geometryID"] = relationships["parents"][0]["ID"];

          skeletons[nodeID] = skeleton;
        } else if (deformerNode["attrType"] == 'BlendShape') {
          Map<String, dynamic> morphTarget = {
            "id": nodeID,
          };

          morphTarget["rawTargets"] = parseMorphTargets(relationships, deformerNodes);
          morphTarget["id"] = nodeID;

          if (relationships["parents"].length > 1){
            console.warning('FBXLoader: morph target attached to more than one geometry is not supported.');
          }

          morphTargets[nodeID] = morphTarget;
        }
      }
    }

    return {
      "skeletons": skeletons,
      "morphTargets": morphTargets,
    };
  }

  // Parse single nodes in _FBXTree.Objects.Deformer
  // The top level skeleton node has type 'Skin' and sub nodes have type 'Cluster'
  // Each skin node represents a skeleton and each cluster node represents a bone
  Map<String, dynamic> parseSkeleton(Map relationships, Map deformerNodes) {
    final rawBones = [];

    relationships["children"].forEach((child) {
      final boneNode = deformerNodes[child["ID"]];

      if (boneNode["attrType"] != 'Cluster') return;

      final rawBone = {
        "ID": child["ID"],
        "indices": [],
        "weights": [],
        "transformLink":
            Matrix4.identity().copyFromUnknown(boneNode["TransformLink"]["a"]),
        // transform: Matrix4().fromArray( boneNode.Transform.a ),
        // linkMode: boneNode.Mode,
      };

      if (boneNode["Indexes"] != null) {
        rawBone["indices"] = boneNode["Indexes"]["a"];
        rawBone["weights"] = boneNode["Weights"]["a"];
      }

      rawBones.add(rawBone);
    });

    return Map<String, dynamic>.from({"rawBones": rawBones, "bones": []});
  }

  // The top level morph deformer node has type "BlendShape" and sub nodes have type "BlendShapeChannel"
  List<Map<String,dynamic>>? parseMorphTargets(Map relationships, Map deformerNodes) {
    final List<Map<String,dynamic>> rawMorphTargets = [];

    for (int i = 0; i < relationships['children'].length; i++) {
      final child = relationships['children'][i];

      final morphTargetNode = deformerNodes[child["ID"]];

      final rawMorphTarget = {
        "name": morphTargetNode.attrName,
        "initialWeight": morphTargetNode.DeformPercent,
        "id": morphTargetNode.id,
        "fullWeights": morphTargetNode.FullWeights.a
      };

      if (morphTargetNode.attrType != 'BlendShapeChannel') return null;

      rawMorphTarget["geoID"] = connections?[_parseInt(child["ID"])].children.filter((child) {
        return child.relationship == null;
      })[0].ID;

      rawMorphTargets.add(rawMorphTarget);
    }

    return rawMorphTargets;
  }

  // create the main Group() to be returned by the loader
  void parseScene(deformers, Map<int?,BufferGeometry> geometryMap, Map<int?,Material> materialMap) {
    sceneGraph = AnimationObject();

    Map modelMap = parseModels(deformers["skeletons"], geometryMap, materialMap);

    final modelNodes = _fbxTree?.objects?["Model"] ?? {};

    final scope = this;
    modelMap.forEach((key, model) {
      final modelNode = modelNodes[model.id];
      scope.setLookAtProperties(model, modelNode);

      final parentConnections = connections?[model.id]["parents"];

      parentConnections.forEach((connection) {
        final parent = modelMap[connection["ID"]];
        if (parent != null) parent.add(model);
      });

      if (model.parent == null) {
        sceneGraph?.add(model);
      }
    });

    bindSkeleton(deformers["skeletons"], geometryMap, modelMap);
    createAmbientLight();

    sceneGraph?.traverse((node) {
      if (node.userData["transformData"] != null) {
        if (node.parent != null) {
          node.userData["transformData"]["parentMatrix"] = node.parent?.matrix;
          node.userData["transformData"]["parentMatrixWorld"] =
              node.parent?.matrixWorld;
        }

        final transform = _generateTransform(node.userData["transformData"]);

        node.applyMatrix4(transform);
        node.updateWorldMatrix(false, false);
      }
    });

    final List<AnimationClip> animations = _AnimationParser().parse();

    // if all the models where already combined in a single group, just return that
    if (sceneGraph?.children.length == 1 && sceneGraph?.children[0] is Group) {
      (sceneGraph?.children[0] as AnimationObject).animations = animations;
      sceneGraph = sceneGraph?.children[0] as AnimationObject;
    }

    sceneGraph?.animations = animations;
  }

  // parse nodes in _FBXTree.Objects.Model
  Map parseModels(skeletons, Map<int?,BufferGeometry> geometryMap, Map<int?,Material> materialMap) {
    final modelMap = {};
    final modelNodes = _fbxTree?.objects?["Model"] ?? {};

    for (final nodeID in modelNodes.keys) {
      final id = _parseInt(nodeID);
      final node = modelNodes[nodeID];
      final relationships = connections?[id];

      Object3D? model = buildSkeleton(relationships, skeletons, id, node["attrName"]);

      if (model == null) {
        switch (node["attrType"]) {
          case 'Camera':
            model = createCamera(relationships);
            break;
          case 'Light':
            model = createLight(relationships);
            break;
          case 'Mesh':
            model = createMesh(relationships, geometryMap, materialMap);
            break;
          case 'NurbsCurve':
            model = createCurve(relationships, geometryMap);
            break;
          case 'LimbNode':
          case 'Root':
            model = Bone();
            break;
          case 'Null':
          default:
            model = AnimationObject();
            break;
        }

        model?.name = node["attrName"] != null
            ? PropertyBinding.sanitizeNodeName(node["attrName"])
            : '';

        model?.id = id ?? 0;
      }

      getTransformData(model, node);
      modelMap[id] = model;
    }

    return modelMap;
  }

  Bone? buildSkeleton(relationships, skeletons, int? id, String? name) {
    Bone? bone;

    relationships["parents"].forEach((parent) {
      for (final iD in skeletons.keys) {
        final skeleton = skeletons[iD];

        skeleton["rawBones"].asMap().forEach((i, rawBone) {
          if (rawBone["ID"] == parent["ID"]) {
            final subBone = bone;
            bone = Bone();

            bone?.matrixWorld.setFrom(rawBone["transformLink"]);

            // set name and id here - otherwise in cases where "subBone" is created it will not have a name / id

            bone?.name = name != null ? PropertyBinding.sanitizeNodeName(name) : '';
            bone?.id = id ?? 0;

            if (skeleton["bones"].length <= i) {
              final boneList = List<Bone>.filled((i + 1) - skeleton["bones"].length, Bone());

              skeleton["bones"].addAll(boneList);
            }

            skeleton["bones"][i] = bone;

            // In cases where a bone is shared between multiple meshes
            // duplicate the bone here and and it as a child of the first bone
            if (subBone != null) {
              bone?.add(subBone);
            }
          }
        });
      }
    });

    return bone;
  }

  // create a PerspectiveCamera or OrthographicCamera
  Object3D? createCamera(relationships) {
    late Object3D model;
    dynamic cameraAttribute;

    relationships.children.forEach((child) {
      final attr = _fbxTree?.objects?["_NodeAttribute"][child["ID"]];

      if (attr != null) {
        cameraAttribute = attr;
      }
    });

    if (cameraAttribute == null) {
      model = Object3D();
    } else {
      num type = 0;
      if (cameraAttribute['CameraProjectionType'] != null && cameraAttribute['CameraProjectionType']['value'] == 1) {
        type = 1;
      }

      double nearClippingPlane = 1;
      if (cameraAttribute['NearPlane'] != null) {
        nearClippingPlane = cameraAttribute['NearPlane']['value'] / 1000;
      }

      double farClippingPlane = 1000;
      if (cameraAttribute['FarPlane'] != null) {
        farClippingPlane = cameraAttribute['FarPlane']['value'] / 1000;
      }

      num width = innerWidth;
      num height = innerHeight;

      if (cameraAttribute['AspectWidth'] != null && cameraAttribute['AspectHeight'] != null) {
        width = cameraAttribute['AspectWidth']['value'];
        height = cameraAttribute['AspectHeight']['value'];
      }

      double aspect = width / height;
      double fov = 45;

      if (cameraAttribute['FieldOfView'] != null) {
        fov = cameraAttribute['FieldOfView']['value'];
      }

      final focalLength = cameraAttribute['FocalLength']
          ? cameraAttribute['FocalLength']['value']
          : null;

      switch (type) {
        case 0: // Perspective
          model = PerspectiveCamera(fov, aspect, nearClippingPlane, farClippingPlane);
          if (focalLength != null) (model as PerspectiveCamera).setFocalLength(focalLength);
          break;

        case 1: // Orthographic
          model = OrthographicCamera(-width / 2, width / 2, height / 2, -height / 2, nearClippingPlane, farClippingPlane);
          break;

        default:
          console.warning('FBXLoader: Unknown camera type $type.');
          model = Object3D();
          break;
      }
    }

    return model;
  }

  // Create a DirectionalLight, PointLight or SpotLight
  Object3D createLight(relationships) {
    late Object3D model;
    dynamic lightAttribute;

    relationships.children.forEach((child) {
      final attr = _fbxTree?.objects?["_NodeAttribute"][child["ID"]];

      if (attr != null) {
        lightAttribute = attr;
      }
    });

    if (lightAttribute == null) {
      model = Object3D();
    } 
    else {
      late int type;

      // LightType can be null for Point lights
      if (lightAttribute.LightType == null) {
        type = 0;
      } else {
        type = lightAttribute.LightType.value;
      }

      Color color = Color.fromHex32(0xffffff);

      if (lightAttribute.Color != null) {
        color = Color.fromList(lightAttribute.Color.value);
      }

      double intensity = (lightAttribute.Intensity == null)
          ? 1
          : lightAttribute.Intensity.value / 100;

      // light disabled
      if (lightAttribute.CastLightOnObject != null &&
          lightAttribute.CastLightOnObject.value == 0) {
        intensity = 0;
      }

      double distance = 0.0;
      if (lightAttribute.FarAttenuationEnd != null) {
        if (lightAttribute.EnableFarAttenuation != null &&
            lightAttribute.EnableFarAttenuation.value == 0) {
          distance = 0.0;
        } else {
          distance = lightAttribute.FarAttenuationEnd.value;
        }
      }

      // TODO: could this be calculated linearly from FarAttenuationStart to FarAttenuationEnd?
      double decay = 1.0;

      switch (type) {
        case 0: // Point
          model = PointLight(color.getHex(), intensity, distance, decay);
          break;

        case 1: // Directional
          model = DirectionalLight(color.getHex(), intensity);
          break;

        case 2: // Spot
          double angle = math.pi / 3;

          if (lightAttribute.InnerAngle != null) {
            angle = lightAttribute.InnerAngle.value.toRad();
          }

          double penumbra = 0;
          if (lightAttribute.OuterAngle != null) {
            // TODO: this is not correct - FBX calculates outer and inner angle in degrees
            // with OuterAngle > InnerAngle && OuterAngle <= Math.pi
            // while three.js uses a penumbra between (0, 1) to attenuate the inner angle
            penumbra = lightAttribute.OuterAngle.value.toRad();
            penumbra = math.max(penumbra, 1);
          }

          model =
              SpotLight(color.getHex(), intensity, distance, angle, penumbra, decay);
          break;

        default:
          console.warning('FBXLoader: Unknown light type ${lightAttribute.LightType.value}, defaulting to a PointLight.');
          model = PointLight(color.getHex(), intensity);
          break;
      }

      if (lightAttribute.CastShadows != null &&
          lightAttribute.CastShadows.value == 1) {
        model.castShadow = true;
      }
    }

    return model;
  }

  Mesh createMesh(relationships, Map<int?,BufferGeometry> geometryMap, Map<int?,Material> materialMap) {
    late Mesh model;
    BufferGeometry? geometry;
    Material? material;
    List<Material?> materials = [];

    // get geometry and materials(s) from connections
    relationships["children"].forEach((child) {
      if (geometryMap.containsKey(child["ID"])) {
        geometry = geometryMap[child["ID"]];
      }

      if (materialMap.containsKey(child["ID"])) {
        materials.add(materialMap[child["ID"]]);
      }
    });

    if (materials.length > 1) {
      material = GroupMaterial(materials as List<Material>);
    } else if (materials.isNotEmpty) {
      material = materials[0];
    } else {
      material = MeshPhongMaterial.fromMap({"color": 0xcccccc});
      materials.add(material);
    }

    if (geometry?.attributes["color"] != null) {
      //materials.forEach((material) {
      for(Material? material in materials){
        material?.vertexColors = true;
      }
    }

    if (geometry?.userData["FBX_Deformer"] != null) {
      model = SkinnedMesh(geometry, material);
      (model as SkinnedMesh).normalizeSkinWeights();
    } else {
      model = Mesh(geometry, material);
    }

    return model;
  }

  Line createCurve(Map relationships, Map geometryMap) {
    late final BufferGeometry geometry;

    for(final map in (relationships['children'] as List)) {
      if (geometryMap.containsKey(map["ID"])){ 
        geometry = geometryMap[map["ID"]];
        break;
      }
    }

    // FBX does not list materials for Nurbs lines, so we'll just put our own in here.
    final material = LineBasicMaterial.fromMap({"color": 0x3300ff, "linewidth": 1});
    return Line(geometry, material);
  }

  // parse the model node for transform data
  void getTransformData(model, Map modelNode) {
    final transformData = {};

    if (modelNode["InheritType"] != null){
      transformData["inheritType"] = _parseInt(modelNode["InheritType"]["value"]);
    }
    if (modelNode["RotationOrder"] != null){
      transformData["eulerOrder"] = _getEulerOrder(modelNode["RotationOrder"]["value"]);
    }
   else{
      transformData["eulerOrder"] = _getEulerOrder(0);//'ZYX';
   }

    if (modelNode["Lcl_Translation"] != null){
      transformData["translation"] = modelNode["Lcl_Translation"]["value"];
    }

    if (modelNode["PreRotation"] != null){
      transformData["preRotation"] = modelNode["PreRotation"]["value"];
    }
    if (modelNode["Lcl_Rotation"] != null){
      transformData["rotation"] = modelNode["Lcl_Rotation"]["value"];
    }
    if (modelNode["PostRotation"] != null){
      transformData["postRotation"] = modelNode["PostRotation"]["value"];
    }

    if (modelNode["Lcl_Scaling"] != null){
      transformData["scale"] = modelNode["Lcl_Scaling"]["value"];
    }

    if (modelNode["ScalingOffset"] != null){
      transformData["scalingOffset"] = modelNode["ScalingOffset"]["value"];
    }
    if (modelNode["ScalingPivot"] != null){
      transformData["scalingPivot"] = modelNode["ScalingPivot"]["value"];
    }

    if (modelNode["RotationOffset"] != null){
      transformData["rotationOffset"] = modelNode["RotationOffset"]["value"];
    }
    if (modelNode["RotationPivot"] != null){
      transformData["rotationPivot"] = modelNode["RotationPivot"]["value"];
    }

    model.userData["transformData"] = transformData;
  }

  void setLookAtProperties(model, Map modelNode) {
    if (modelNode["LookAtProperty"] != null) {
      final children = connections?[model.id].children;

      children.forEach((child) {
        if (child.relationship == 'LookAtProperty') {
          final lookAtTarget = _fbxTree?.objects?["Model"][child["ID"]];

          if (lookAtTarget.Lcl_Translation != null) {
            final pos = lookAtTarget.Lcl_Translation.value;

            // DirectionalLight, SpotLight
            if (model.target != null) {
              model.target.position.fromArray(pos);
              sceneGraph?.add(model.target);
            } 
            else {
              model.lookAt(Vector3.zero().copyFromUnknown(pos));
            }
          }
        }
      });
    }
  }

  void bindSkeleton(skeletons, geometryMap, modelMap) {
    final bindMatrices = parsePoseNodes();

    for (final iD in skeletons.keys) {
      final skeleton = skeletons[iD];

      final parents = connections?[_parseInt(skeleton["ID"])]["parents"];

      parents.forEach((parent) {
        if (geometryMap.containsKey(parent["ID"])) {
          final geoID = parent["ID"];
          final geoRelationships = connections?[geoID];

          geoRelationships["parents"].forEach((geoConnParent) {
            if (modelMap.containsKey(geoConnParent["ID"])) {
              final model = modelMap[geoConnParent["ID"]];

              model.bind(Skeleton(List<Bone>.from(skeleton["bones"])),
                  bindMatrices[geoConnParent["ID"]]);
            }
          });
        }
      });
    }
  }

  Map parsePoseNodes() {
    final bindMatrices = {};

    if (_fbxTree?.objects?.keys.contains("Pose") ?? false) {
      final bindPoseNode = _fbxTree?.objects?["Pose"];

      for (final nodeID in bindPoseNode.keys) {
        if (bindPoseNode[nodeID]["attrType"] == 'BindPose' &&
            bindPoseNode[nodeID]["NbPoseNodes"] > 0) {
          final poseNodes = bindPoseNode[nodeID]["PoseNode"];

          if (poseNodes is List) {
            //poseNodes.forEach((poseNode) {
            for(dynamic poseNode in poseNodes){
              bindMatrices[poseNode["Node"]] =
                  Matrix4.identity().copyFromUnknown(poseNode["Matrix"]["a"]);
            }
          } else {
            bindMatrices[poseNodes["Node"]] =
                Matrix4.identity().copyFromUnknown(poseNodes["Matrix"]["a"]);
          }
        }
      }
    }

    return bindMatrices;
  }

  // Parse ambient color in _FBXTree.GlobalSettings - if it's not set to black (default), create an ambient light
  void createAmbientLight() {
    if (_fbxTree?.globalSettings?["AmbientColor"] != null) {
      final ambientColor = _fbxTree?.globalSettings!["AmbientColor"]["value"];
      final r = ambientColor[0];
      final g = ambientColor[1];
      final b = ambientColor[2];

      if (r != 0 || g != 0 || b != 0) {
        final color = Color(r, g, b);
        sceneGraph?.add(AmbientLight(color.getHex(), 1));
      }
    }
  }
}

// parse Geometry data from _FBXTree and return map of BufferGeometries
class _GeometryParser {
  // Parse nodes in _FBXTree.Objects.Geometry
  Map<int?,BufferGeometry> parse(deformers) {
    final Map<int?,BufferGeometry> geometryMap = {};
    if (_fbxTree?.objects?["Geometry"] != null) {
      final geoNodes = _fbxTree?.objects!["Geometry"];
      
      for (final nodeID in geoNodes.keys) {
        final relationships = connections?[_parseInt(nodeID)];
        final geo = parseGeometry(relationships, geoNodes[nodeID], deformers);

        geometryMap[_parseInt(nodeID)] = geo!;
      }
    }

    return geometryMap;
  }

  // Parse single node in _FBXTree.Objects.Geometry
  BufferGeometry? parseGeometry(relationships, geoNode, deformers) {
    switch (geoNode["attrType"]) {
      case 'Mesh':
        return parseMeshGeometry(relationships, geoNode, deformers);
      case 'NurbsCurve':
        return parseNurbsGeometry(geoNode);
    }

    return null;
  }

  // Parse single node mesh geometry in _FBXTree.Objects.Geometry
  BufferGeometry? parseMeshGeometry(relationships, geoNode, deformers) {
    final skeletons = deformers["skeletons"];
    final morphTargets = [];

    List modelNodes = relationships["parents"].map((parent) {
      return _fbxTree?.objects?["Model"][parent["ID"]];
    }).toList();

    // don't create geometry if it is not associated with any models
    if (modelNodes.isEmpty) return null;

    dynamic skeleton;
    for (final child in relationships["children"]) {
      if (skeletons[child["ID"]] != null) {
        skeleton = skeletons[child["ID"]];
      }
    }

    relationships["children"].forEach((child) {
      if (deformers["morphTargets"][child["ID"]] != null) {
        morphTargets.add(deformers["morphTargets"][child["ID"]]);
      }
    });

    // Assume one model and get the preRotation from that
    // if there is more than one model associated with the geometry this may cause problems
    Map modelNode = modelNodes[0];

    final Map<String,dynamic> transformData = {};

    if (modelNode['RotationOrder'] != null){
      transformData["eulerOrder"] = _getEulerOrder(modelNode["RotationOrder"]["value"]);
    }
    if (modelNode['InheritType'] != null){
      transformData["inheritType"] = _parseInt(modelNode["InheritType"]["value"]);
    }

    if (modelNode['GeometricTranslation'] != null){
      transformData["translation"] = modelNode["GeometricTranslation"]["value"];
    }
    if (modelNode['GeometricRotation'] != null){
      transformData["rotation"] = modelNode["GeometricRotation"]["value"];
    }
    if (modelNode['GeometricScaling'] != null){
      transformData["scale"] = modelNode["GeometricScaling"]["value"];
    }

    final transform = _generateTransform(transformData);

    return genGeometry(geoNode, skeleton, morphTargets, transform);
  }

  // Generate a BufferGeometry from a node in _FBXTree.Objects.Geometry
  BufferGeometry genGeometry(Map<String,dynamic> geoNode, skeleton, List morphTargets, Matrix4 preTransform) {
    final geo = BufferGeometry();
    if (geoNode["attrName"] != null) geo.name = geoNode["attrName"];

    final geoInfo = parseGeoNode(geoNode, skeleton);
    final buffers = genBuffers(geoInfo);

    final positionAttribute = Float32BufferAttribute.fromList(
        List<double>.from(buffers.vertex), 3);

    positionAttribute.applyMatrix4(preTransform);

    geo.setAttributeFromString('position', positionAttribute);

    if (buffers.colors.isNotEmpty) {
      geo.setAttributeFromString('color', Float32BufferAttribute.fromList(buffers.colors, 3));
    }

    if (skeleton != null) {
      geo.setAttributeFromString(
          'skinIndex',
          Uint16BufferAttribute.fromList(
              List<int>.from(buffers.weightsIndices),
              4));

      geo.setAttributeFromString(
          'skinWeight',
          Float32BufferAttribute.fromList(
              List<double>.from(
                  buffers.vertexWeights.map((e) => e.toDouble())),
              4));

      // used later to bind the skeleton to the model
      geo.userData["FBX_Deformer"] = skeleton;
    }

    if (buffers.normal.isNotEmpty) {
      final normalMatrix = Matrix3.identity().getNormalMatrix(preTransform);

      final normalAttribute = Float32BufferAttribute.fromList(
          List<double>.from(buffers.normal), 3);
      normalAttribute.applyNormalMatrix(normalMatrix);

      geo.setAttributeFromString('normal', normalAttribute);
    }

    buffers.uvs.asMap().forEach((i, uvBuffer) {
      String name = 'uv${(i + 1)}';

      // the first uv buffer is just called 'uv'
      if (i == 0) {
        name = 'uv';
      }

      geo.setAttributeFromString(name,Float32BufferAttribute.fromList(List<double>.from(buffers.uvs[i]), 2));
    });

    if (geoInfo["material"] != null &&
        geoInfo["material"]["mappingType"] != 'AllSame') {
      // Convert the material indices of each vertex into rendering groups on the geometry.
      int prevMaterialIndex = buffers.materialIndex[0];
      int startIndex = 0;

      buffers.materialIndex.asMap().forEach((i, currentIndex) {
        if (currentIndex != prevMaterialIndex) {
          geo.addGroup(startIndex, i - startIndex, prevMaterialIndex);

          prevMaterialIndex = currentIndex;
          startIndex = i;
        }
      });

      // the loop above doesn't add the last group, do that here.
      if (geo.groups.isNotEmpty) {
        final lastGroup = geo.groups[geo.groups.length - 1];
        final int lastIndex = (lastGroup["start"] + lastGroup["count"]).toInt();

        if (lastIndex != buffers.materialIndex.length) {
          geo.addGroup(lastIndex, buffers.materialIndex.length - lastIndex,prevMaterialIndex);
        }
      }

      // case where there are multiple materials but the whole geometry is only
      // using one of them
      if (geo.groups.isEmpty) {
        geo.addGroup(0, buffers.materialIndex.length,buffers.materialIndex[0].toInt());
      }
    }

    addMorphTargets(geo, geoNode, morphTargets, preTransform);

    return geo;
  }

  Map<String,dynamic> parseGeoNode(Map<String,dynamic> geoNode, skeleton) {
    final Map<String,dynamic> geoInfo = {};

    geoInfo["vertexPositions"] =
        (geoNode["Vertices"] != null) ? geoNode["Vertices"]["a"] : [];
    geoInfo["vertexIndices"] = (geoNode["PolygonVertexIndex"] != null)
        ? geoNode["PolygonVertexIndex"]["a"]
        : [];

    if (geoNode["LayerElementColor"] != null) {
      geoInfo["color"] = parseVertexColors(geoNode["LayerElementColor"][0]);
    }

    if (geoNode["LayerElementMaterial"] != null) {
      geoInfo["material"] = parseMaterialIndices(geoNode["LayerElementMaterial"][0]);
    }

    if (geoNode["LayerElementNormal"] != null) {
      geoInfo['normal'] = parseNormals(geoNode["LayerElementNormal"][0]);
    }

    if (geoNode["LayerElementUV"] != null) {
      geoInfo["uv"] = [];

      int i = 0;
      while (geoNode["LayerElementUV"][i] != null) {
        if (geoNode["LayerElementUV"][i]["UV"] != null) {
          geoInfo["uv"].add(parseUVs(geoNode["LayerElementUV"][i]));
        }

        i++;
      }
    }

    geoInfo["weightTable"] = {};

    if (skeleton != null) {
      geoInfo["skeleton"] = skeleton;

      if (skeleton["rawBones"] != null){
        skeleton["rawBones"].asMap().forEach((i, rawBone) {
          // loop over the bone's vertex indices and weights
          rawBone["indices"].asMap().forEach((j, index) {
            if (geoInfo["weightTable"][index] == null){
              geoInfo["weightTable"][index] = [];
            }

            geoInfo["weightTable"][index].add({
              "id": i,
              "weight": rawBone["weights"][j],
            });
          });
        });
      }
    }

    return geoInfo;
  }

  MorphBuffers genBuffers(geoInfo) {
    final buffers = MorphBuffers();

    int polygonIndex = 0;
    int faceLength = 0;
    bool displayedWeightsWarning = false;

    // these will hold data for a single face
    List<num> facePositionIndexes = [];
    List<num> faceNormals = [];
    List<num> faceColors = [];
    List<List<num>> faceUVs = [];
    List<num> faceWeights = [];
    List<num> faceWeightIndices = [];

    final scope = this;
    geoInfo["vertexIndices"].asMap().forEach((polygonVertexIndex, vertexIndex) {
      int? materialIndex;
      bool endOfFace = false;

      // Face index and vertex index arrays are combined in a single array
      // A cube with quad faces looks like this:
      // PolygonVertexIndex: *24 {
      //  a: 0, 1, 3, -3, 2, 3, 5, -5, 4, 5, 7, -7, 6, 7, 1, -1, 1, 7, 5, -4, 6, 0, 2, -5
      //  }
      // Negative numbers mark the end of a face - first face here is 0, 1, 3, -3
      // to find index of last vertex bit shift the index: ^ - 1
      if (vertexIndex < 0) {
        vertexIndex = vertexIndex ^ -1; // equivalent to ( x * -1 ) - 1
        endOfFace = true;
      }

      List<num> weightIndices = [];
      List<num> weights = [];

      facePositionIndexes.addAll([vertexIndex * 3, vertexIndex * 3 + 1, vertexIndex * 3 + 2]);

      if (geoInfo["color"] != null) {
        final data = _getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo["color"]);

        faceColors.addAll([data[0], data[1], data[2]]);
      }

      if (geoInfo["skeleton"] != null) {
        if (geoInfo["weightTable"][vertexIndex] != null) {
          geoInfo["weightTable"][vertexIndex].forEach((wt) {
            weights.add(wt["weight"]);
            weightIndices.add(wt["id"]);
          });
        }

        if (weights.length > 4) {
          if (!displayedWeightsWarning) {
            console.warning('FBXLoader: Vertex has more than 4 skinning weights assigned to vertex. Deleting additional weights.');
            displayedWeightsWarning = true;
          }

          List<num> wIndex = [0, 0, 0, 0];
          List<num> weight_ = [0, 0, 0, 0];

          weights.asMap().forEach((weightIndex, weight) {
            num currentWeight = weight;
            num currentIndex = weightIndices[weightIndex];

            List<num> comparedWeightArray = weight_;

            weight_.asMap().forEach((comparedWeightIndex, comparedWeight) {
              if (currentWeight > comparedWeight) {
                comparedWeightArray[comparedWeightIndex] = currentWeight;
                currentWeight = comparedWeight;

                final tmp = wIndex[comparedWeightIndex];
                wIndex[comparedWeightIndex] = currentIndex;
                currentIndex = tmp;
              }
            });
          });

          weightIndices = wIndex;
          weights = weight_;
        }

        // if the weight array is shorter than 4 pad with 0s
        while (weights.length < 4) {
          weights.add(0);
          weightIndices.add(0);
        }

        for (int i = 0; i < 4; ++i) {
          faceWeights.add(weights[i]);
          faceWeightIndices.add(weightIndices[i]);
        }
      }

      if (geoInfo['normal'] != null) {
        final data = _getData(
            polygonVertexIndex, polygonIndex, vertexIndex, geoInfo['normal']);

        faceNormals.addAll([data[0], data[1], data[2]]);
      }

      if (geoInfo["material"] != null &&
          geoInfo["material"]["mappingType"] != 'AllSame') {
        materialIndex = _getData(polygonVertexIndex, polygonIndex, vertexIndex,
            geoInfo["material"])[0];
      }

      if (geoInfo["uv"] != null) {
        geoInfo["uv"].asMap().forEach((i, uv) {
          final data = _getData(polygonVertexIndex, polygonIndex, vertexIndex, uv);
          if (faceUVs.length == i) {
            faceUVs.add([]);
          }

          faceUVs[i].addAll([data[0],data[1]]);
        });
      }

      faceLength++;

      if (endOfFace) {
        scope.genFace(
          buffers,
          geoInfo,
          facePositionIndexes,
          materialIndex,
          faceNormals,
          faceColors,
          faceUVs,
          faceWeights,
          faceWeightIndices,
          faceLength
        );

        polygonIndex++;
        faceLength = 0;

        // reset arrays for the next face
        facePositionIndexes = [];
        faceNormals = [];
        faceColors = [];
        faceUVs = [];
        faceWeights = [];
        faceWeightIndices = [];
      }
    });

    return buffers;
  }

	// See https://www.khronos.org/opengl/wiki/Calculating_a_Surface_Normal
	Vector3 getNormalNewell(List<Vector3> vertices ) {
		final normal = Vector3( 0.0, 0.0, 0.0 );

		for (int i = 0; i < vertices.length; i ++ ) {
			final current = vertices[ i ];
			final next = vertices[ ( i + 1 ) % vertices.length ];

			normal.x += ( current.y - next.y ) * ( current.z + next.z );
			normal.y += ( current.z - next.z ) * ( current.x + next.x );
			normal.z += ( current.x - next.x ) * ( current.y + next.y );
		}

		normal.normalize();

		return normal;
	}

	Map<String,dynamic> getNormalTangentAndBitangent(List<Vector3> vertices ) {
		final normalVector = this.getNormalNewell( vertices );
		// Avoid up being equal or almost equal to normalVector
		final up = normalVector.z.abs() > 0.5 ? Vector3( 0.0, 1.0, 0.0 ) : Vector3( 0.0, 0.0, 1.0 );
		final tangent = up.cross( normalVector ).normalize();
		final bitangent = normalVector.clone().cross( tangent ).normalize();

		return {
			'normal': normalVector,
			'tangent': tangent,
			'bitangent': bitangent
		};

	}

	Vector2 flattenVertex(Vector vertex, Vector normalTangent, Vector normalBitangent ) {
		return Vector2(
			vertex.dot( normalTangent ),
			vertex.dot( normalBitangent )
		);
	}


  // Generate data for a single face in a geometry. If the face is a quad then split it into 2 tris
  void genFace(
    MorphBuffers buffers,
    Map geoInfo,
    facePositionIndexes,
    materialIndex,
    faceNormals,
    faceColors,
    faceUVs,
    faceWeights,
    faceWeightIndices,
    faceLength
  ){
		List<List<num>> triangles;

		if ( faceLength > 3 ) {

			// Triangulate n-gon using earcut

			final List<Vector3> vertices = [];
			// in morphing scenario vertexPositions represent morphPositions
			// while baseVertexPositions represent the original geometry's positions
			final positions = geoInfo['baseVertexPositions'] ?? geoInfo['vertexPositions'];
			for (int i = 0; i < facePositionIndexes.length; i += 3 ) {

				vertices.add(
					Vector3(
						positions[ facePositionIndexes[ i ] ],
						positions[ facePositionIndexes[ i + 1 ] ],
						positions[ facePositionIndexes[ i + 2 ] ]
					)
				);

			}
      final  gntab = getNormalTangentAndBitangent( vertices );
			final tangent = gntab['tangent'];
      final bitangent = gntab['bitangent'];
			final List<Vector?> triangulationInput = [];

			for ( final vertex in vertices ) {
				triangulationInput.add( this.flattenVertex( vertex, tangent, bitangent ) );
			}

			// When vertices is an array of [0,0,0] elements (which is the case for vertices not participating in morph)
			// the triangulationInput will be an array of [0,0] elements
			// resulting in an array of 0 triangles being returned from ShapeUtils.triangulateShape
			// leading to not pushing into buffers.vertex the redundant vertices (the vertices that are not morphed).
			// That's why, in order to support morphing scenario, "positions" is looking first for baseVertexPositions,
			// so that we don't end up with an array of 0 triangles for the faces not participating in morph.
			triangles = ShapeUtils.triangulateShape( triangulationInput, [] );

		} else {
			// Regular triangle, skip earcut triangulation step
			triangles = [[ 0, 1, 2 ]];
		}

    for(final i in triangles){//(int i = 2; i < faceLength; i++) {
      final i0 = i[0].toInt();
      final i1 = i[1].toInt();
      final i2 = i[2].toInt();

      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i0 * 3]]);
      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i0 * 3 + 1]]);
      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i0 * 3 + 2]]);

      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i1 * 3]]);
      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i1 * 3 + 1]]);
      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i1 * 3 + 2]]);

      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i2 * 3]]);
      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i2 * 3 + 1]]);
      buffers.vertex.add(geoInfo["vertexPositions"][facePositionIndexes[i2 * 3 + 2]]);

      if (geoInfo["skeleton"] != null) {
        buffers.vertexWeights.add(faceWeights[i0 * 4]);
        buffers.vertexWeights.add(faceWeights[i0 * 4 + 1]);
        buffers.vertexWeights.add(faceWeights[i0 * 4 + 2]);
        buffers.vertexWeights.add(faceWeights[i0 * 4 + 3]);

        buffers.vertexWeights.add(faceWeights[i1 * 4]);
        buffers.vertexWeights.add(faceWeights[i1  * 4 + 1]);
        buffers.vertexWeights.add(faceWeights[i1  * 4 + 2]);
        buffers.vertexWeights.add(faceWeights[i1  * 4 + 3]);

        buffers.vertexWeights.add(faceWeights[i2 * 4]);
        buffers.vertexWeights.add(faceWeights[i2 * 4 + 1]);
        buffers.vertexWeights.add(faceWeights[i2 * 4 + 2]);
        buffers.vertexWeights.add(faceWeights[i2 * 4 + 3]);

        buffers.weightsIndices.add(faceWeightIndices[i0 * 4]);
        buffers.weightsIndices.add(faceWeightIndices[i0 * 4 + 1]);
        buffers.weightsIndices.add(faceWeightIndices[i0 * 4 + 2]);
        buffers.weightsIndices.add(faceWeightIndices[i0 * 4 + 3]);

        buffers.weightsIndices.add(faceWeightIndices[i1 * 4]);
        buffers.weightsIndices.add(faceWeightIndices[i1 * 4 + 1]);
        buffers.weightsIndices.add(faceWeightIndices[i1 * 4 + 2]);
        buffers.weightsIndices.add(faceWeightIndices[i1 * 4 + 3]);

        buffers.weightsIndices.add(faceWeightIndices[i2 * 4]);
        buffers.weightsIndices.add(faceWeightIndices[i2 * 4 + 1]);
        buffers.weightsIndices.add(faceWeightIndices[i2 * 4 + 2]);
        buffers.weightsIndices.add(faceWeightIndices[i2 * 4 + 3]);
      }

      if (geoInfo["color"] != null) {
        buffers.colors.add(faceColors[i0 * 3]);
        buffers.colors.add(faceColors[i0 * 3 + 1]);
        buffers.colors.add(faceColors[i0 * 3 + 2]);

        buffers.colors.add(faceColors[i1 * 3]);
        buffers.colors.add(faceColors[i1 * 3 + 1]);
        buffers.colors.add(faceColors[i1 * 3 + 2]);

        buffers.colors.add(faceColors[i2 * 3]);
        buffers.colors.add(faceColors[i2 * 3 + 1]);
        buffers.colors.add(faceColors[i2 * 3 + 2]);
      }

      if (geoInfo["material"] != null &&
          geoInfo["material"]["mappingType"] != 'AllSame') {
        buffers.materialIndex.add(materialIndex);
        buffers.materialIndex.add(materialIndex);
        buffers.materialIndex.add(materialIndex);
      }

      if (geoInfo['normal'] != null) {
        buffers.normal.add(faceNormals[i0 * 3]);
        buffers.normal.add(faceNormals[i0 * 3 + 1]);
        buffers.normal.add(faceNormals[i0 * 3 + 2]);

        buffers.normal.add(faceNormals[i1 * 3]);
        buffers.normal.add(faceNormals[i1 * 3 + 1]);
        buffers.normal.add(faceNormals[i1 * 3 + 2]);

        buffers.normal.add(faceNormals[i2 * 3]);
        buffers.normal.add(faceNormals[i2 * 3 + 1]);
        buffers.normal.add(faceNormals[i2 * 3 + 2]);
      }
      
      if (geoInfo["uv"] != null) {
        final map = (geoInfo["uv"] as List).asMap();

        map.forEach((j, uv) {
          if ( buffers.uvs.length == j ){ 
            buffers.uvs.add([]);
          }
          
          buffers.uvs[j].addAll([
            faceUVs[j][i0 * 2],
            faceUVs[j][i0 * 2 + 1],
            faceUVs[j][i1 * 2],
            faceUVs[j][i1 * 2 + 1],
            faceUVs[j][i2 * 2],
            faceUVs[j][i2 * 2 + 1]
          ]);
        });
      }
    }
  }

  void addMorphTargets(BufferGeometry parentGeo, Map<String,dynamic> parentGeoNode, List morphTargets, Matrix4 preTransform) {
    if (morphTargets.length == 0) return;

    parentGeo.morphTargetsRelative = true;

    parentGeo.morphAttributes['position'] = [];
    parentGeo.morphAttributes['normal'] = []; // not implemented

    final scope = this;
    morphTargets.forEach((morphTarget) {
      morphTarget.rawTargets.forEach((rawTarget) {
        final morphGeoNode = _fbxTree?.objects?["Geometry"][rawTarget.geoID];

        if (morphGeoNode != null) {
          scope.genMorphGeometry(parentGeo, parentGeoNode, morphGeoNode,
              preTransform, rawTarget.name);
        }
      });
    });
  }

  // a morph geometry node is similar to a standard  node, and the node is also contained
  // in _FBXTree.Objects.Geometry, however it can only have attributes for position, normal
  // and a special attribute Index defining which vertices of the original geometry are affected
  // Normal and position attributes only have data for the vertices that are affected by the morph
  void genMorphGeometry(BufferGeometry parentGeo, Map<String,dynamic> parentGeoNode, morphGeoNode, Matrix4 preTransform, String? name) {
    final basePositions = parentGeoNode['Vertices'] != null ? parentGeoNode['Vertices']['a'] : [];
    final vertexIndices = (parentGeoNode['PolygonVertexIndex'] != null)? parentGeoNode['PolygonVertexIndex']['a']: [];

    final morphPositionsSparse = (morphGeoNode['Vertices'] != null) ? morphGeoNode['Vertices']['a'] : [];
    final indices = (morphGeoNode['Indexes'] != null) ? morphGeoNode['Indexes']['a'] : [];

    final length = parentGeo.attributes['position'].length * 3;
    final morphPositions = Float32List(length);

    for (int i = 0; i < indices.length; i++) {
      final morphIndex = indices[i] * 3;

      morphPositions[morphIndex] = morphPositionsSparse[i * 3];
      morphPositions[morphIndex + 1] = morphPositionsSparse[i * 3 + 1];
      morphPositions[morphIndex + 2] = morphPositionsSparse[i * 3 + 2];
    }

    // TODO: add morph normal support
    final morphGeoInfo = {
      "vertexIndices": vertexIndices,
      "vertexPositions": morphPositions,
      "baseVertexPositions": basePositions
    };

    final morphBuffers = genBuffers(morphGeoInfo);

    final positionAttribute = Float32BufferAttribute.fromList(morphBuffers.vertex, 3);
    positionAttribute.name = name ?? morphGeoNode['attrName'];

    positionAttribute.applyMatrix4(preTransform);

    parentGeo.morphAttributes['position']?.add(positionAttribute);
  }

  // Parse normal from _FBXTree.Objects.Geometry.LayerElementNormal if it exists
  Map<String,dynamic> parseNormals(Map normalNode) {
    final mappingType = normalNode["MappingInformationType"];
    final referenceType = normalNode["ReferenceInformationType"];
    final buffer = normalNode["Normals"]["a"];
    var indexBuffer = [];
    if (referenceType == 'IndexToDirect') {
      if (normalNode["NormalIndex"] != null) {
        indexBuffer = normalNode["NormalIndex"]["a"];
      } else if (normalNode["NormalsIndex"] != null) {
        indexBuffer = normalNode["NormalsIndex"]["a"];
      }
    }

    return {
      "dataSize": 3,
      "buffer": buffer,
      "indices": indexBuffer,
      "mappingType": mappingType,
      "referenceType": referenceType
    };
  }

  // Parse UVs from _FBXTree.Objects.Geometry.LayerElementUV if it exists
  Map<String,dynamic> parseUVs(Map uvNode) {
    final mappingType = uvNode["MappingInformationType"];
    final referenceType = uvNode["ReferenceInformationType"];
    final buffer = uvNode["UV"]["a"];
    var indexBuffer = [];
    if (referenceType == 'IndexToDirect') {
      indexBuffer = uvNode["UVIndex"]["a"];
    }

    return {
      "dataSize": 2,
      "buffer": buffer,
      "indices": indexBuffer,
      "mappingType": mappingType,
      "referenceType": referenceType
    };
  }

  // Parse Vertex Colors from _FBXTree.Objects.Geometry.LayerElementColor if it exists
  Map<String,dynamic> parseVertexColors(Map colorNode) {
    final mappingType = colorNode['MappingInformationType'];
    final referenceType = colorNode['ReferenceInformationType'];
    final buffer = colorNode['Colors']['a'];
    var indexBuffer = [];
    if (referenceType == 'IndexToDirect') {
      indexBuffer = colorNode['ColorIndex']['a'];
    }

		for (var i = 0, c = Color(); i < buffer.length; i += 4 ) {
			c.fromUnknown( buffer, i );
			ColorManagement.toWorkingColorSpace( c, ColorSpace.srgb );//colorSpaceToWorking
			c.copyIntoList( buffer, i );
		}

    return {
      "dataSize": 4,
      "buffer": buffer,
      "indices": indexBuffer,
      "mappingType": mappingType,
      "referenceType": referenceType
    };
  }

  // Parse mapping and material data in _FBXTree.Objects.Geometry.LayerElementMaterial if it exists
  Map<String,dynamic> parseMaterialIndices(Map materialNode) {
    final mappingType = materialNode["MappingInformationType"];
    final referenceType = materialNode["ReferenceInformationType"];

    if (mappingType == 'NoMappingInformation') {
      return {
        "dataSize": 1,
        "buffer": [0],
        "indices": [0],
        "mappingType": 'AllSame',
        "referenceType": referenceType
      };
    }

    final materialIndexBuffer = materialNode["Materials"]["a"];

    // Since materials are stored as indices, there's a bit of a mismatch between FBX and what
    // we expect.So we create an intermediate buffer that points to the index in the buffer,
    // for conforming with the other functions we've written for other data.
    final materialIndices = [];

    for (int i = 0; i < materialIndexBuffer.length; ++i) {
      materialIndices.add(i);
    }

    return {
      "dataSize": 1,
      "buffer": materialIndexBuffer,
      "indices": materialIndices,
      "mappingType": mappingType,
      "referenceType": referenceType
    };
  }

  // Generate a NurbGeometry from a node in _FBXTree.Objects.Geometry
  BufferGeometry parseNurbsGeometry(Map geoNode) {
    final order = int.tryParse(geoNode['Order']);

    if (order == null) {
      console.warning('FBXLoader: Invalid Order ${geoNode['Order']} given for geometry ID: ${geoNode['id']}');
      return BufferGeometry();
    }

    final degree = order - 1;

    final knots = geoNode['KnotVector']['a'];
    final List<Vector> controlPoints = [];
    final pointsValues = geoNode['Points']['a'];

    for (int i = 0, l = pointsValues.length; i < l; i += 4) {
      controlPoints.add(Vector4.zero().copyFromUnknown(pointsValues, i));
    }

    int? startKnot, endKnot;
    if (geoNode['Form'] == 'Closed') {
      controlPoints.add(controlPoints[0]);
    } 
    else if (geoNode['Form'] == 'Periodic') {
      startKnot = degree;
      endKnot = knots.length - 1 - startKnot;

      for (int i = 0; i < degree; ++i) {
        controlPoints.add(controlPoints[i]);
      }
    }

    final curve = NURBSCurve(degree, knots, controlPoints, startKnot, endKnot);
    final points = curve.getPoints(controlPoints.length * 12);

    return BufferGeometry().setFromPoints(points);
  }
}

// parse animation data from _FBXTree
class _AnimationParser {
  // take raw animation clips and turn them into three.js animation clips
  List<AnimationClip> parse() {
    final List<AnimationClip> animationClips = [];

    final rawClips = parseClips();

    if (rawClips != null) {
      for (final key in rawClips.keys) {
        final rawClip = rawClips[key];

        final clip = addClip(rawClip);

        animationClips.add(clip);
      }
    }

    return animationClips;
  }

  parseClips() {
    // since the actual transformation data is stored in _FBXTree.Objects.AnimationCurve,
    // if this is null we can safely assume there are no animations
    if (_fbxTree?.objects?["AnimationCurve"] == null) return null;

    final curveNodesMap = parseAnimationCurveNodes();

    parseAnimationCurves(curveNodesMap);

    final layersMap = parseAnimationLayers(curveNodesMap);
    final rawClips = parseAnimStacks(layersMap);

    return rawClips;
  }

  // parse nodes in _FBXTree.Objects.AnimationCurveNode
  // each AnimationCurveNode holds data for an animation transform for a model (e.g. left arm rotation )
  // and is referenced by an AnimationLayer
  parseAnimationCurveNodes() {
    final rawCurveNodes = _fbxTree?.objects?["AnimationCurveNode"];

    final curveNodesMap = {};

    for (final nodeID in rawCurveNodes.keys) {
      final rawCurveNode = rawCurveNodes[nodeID];

      if (RegExp(r'S|R|T|DeformPercent').hasMatch(rawCurveNode["attrName"])) {
        final curveNode = {
          "id": rawCurveNode["id"],
          "attr": rawCurveNode["attrName"],
          "curves": {},
        };

        curveNodesMap[curveNode["id"]] = curveNode;
      }
    }

    return curveNodesMap;
  }

  // parse nodes in _FBXTree.Objects.AnimationCurve and connect them up to
  // previously parsed AnimationCurveNodes. Each AnimationCurve holds data for a single animated
  // axis ( e.g. times and values of x rotation)
  parseAnimationCurves(curveNodesMap) {
    final rawCurves = _fbxTree?.objects?["AnimationCurve"];

    // TODO: Many values are identical up to roundoff error, but won't be optimised
    // e.g. position times: [0, 0.4, 0. 8]
    // position values: [7.23538335023477e-7, 93.67518615722656, -0.9982695579528809, 7.23538335023477e-7, 93.67518615722656, -0.9982695579528809, 7.235384487103147e-7, 93.67520904541016, -0.9982695579528809]
    // clearly, this should be optimised to
    // times: [0], positions [7.23538335023477e-7, 93.67518615722656, -0.9982695579528809]
    // this shows up in nearly every FBX file, and generally time array is length > 100

    for (final nodeID in rawCurves.keys) {
      final animationCurve = {
        "id": rawCurves[nodeID]["id"],
        "times": rawCurves[nodeID]["KeyTime"]["a"]
            .map(_convertFBXTimeToSeconds)
            .toList(),
        "values": rawCurves[nodeID]["KeyValueFloat"]["a"],
      };

      final relationships = connections?[animationCurve["id"]];

      if (relationships != null) {
        final animationCurveID = relationships["parents"][0]["ID"];
        final animationCurveRelationship =
            relationships["parents"][0]["relationship"];

        if (RegExp(r'X').hasMatch(animationCurveRelationship)) {
          curveNodesMap[animationCurveID]["curves"]['x'] = animationCurve;
        } 
        else if (RegExp(r'Y').hasMatch(animationCurveRelationship)) {
          curveNodesMap[animationCurveID]["curves"]['y'] = animationCurve;
        } 
        else if (RegExp(r'Z').hasMatch(animationCurveRelationship)) {
          curveNodesMap[animationCurveID]["curves"]['z'] = animationCurve;
        } 
        else if (RegExp(r'd|DeformPercent')
          .hasMatch(animationCurveRelationship) &&
          curveNodesMap.has(animationCurveID)
        ) {
          curveNodesMap[animationCurveID]["curves"]['morph'] = animationCurve;
        }
      }
    }
  }

  // parse nodes in _FBXTree.Objects.AnimationLayer. Each layers holds references
  // to various AnimationCurveNodes and is referenced by an AnimationStack node
  // note: theoretically a stack can have multiple layers, however in practice there always seems to be one per stack
  Map parseAnimationLayers(curveNodesMap) {
    final rawLayers = _fbxTree?.objects?["AnimationLayer"];
    Map layersMap = {};

    for (final nodeID in rawLayers.keys) {
      final layerCurveNodes = [];

      final connection = connections?[int.parse(nodeID.toString())];

      if (connection != null) {
        // all the animationCurveNodes used in the layer
        final children = connection["children"];

        children.asMap().forEach((i, child) {
          if (curveNodesMap.containsKey(child["ID"])) {
            final curveNode = curveNodesMap[child["ID"]];

            // check that the curves are defined for at least one axis, otherwise ignore the curveNode
            if (curveNode["curves"]["x"] != null ||
                curveNode["curves"]["y"] != null ||
                curveNode["curves"]["z"] != null) {
              final modelID = connections?[child["ID"]]["parents"].where((parent) {
                return parent["relationship"] != null;
              }).toList()[0]["ID"];

              if (modelID != null) {
                final rawModel = _fbxTree?.objects?["Model"][modelID];

                if (rawModel == null) {
                  console.warning('FBXLoader: Encountered a unused curve. $child');
                  return;
                }

                final node = {
                  "modelName": rawModel["attrName"] != null
                      ? PropertyBinding.sanitizeNodeName(rawModel["attrName"])
                      : '',
                  "ID": rawModel["id"],
                  "initialPosition": [0, 0, 0],
                  "initialRotation": [0, 0, 0],
                  "initialScale": [1, 1, 1],
                };

                sceneGraph?.traverse((child) {
                  if (child.id == rawModel["id"]) {
                    node["transform"] = child.matrix;

                    if (child.userData["transformData"] != null){
                      node["eulerOrder"] = child.userData["transformData"]["eulerOrder"];
                    }
                  }
                });

                if (node["transform"] == null){
                  node["transform"] = Matrix4();
                }

                // if the animated model is pre rotated, we'll have to apply the pre rotations to every
                // animation value as well
                if (rawModel.keys.contains('PreRotation')){
                  node["preRotation"] = rawModel["PreRotation"]["value"];
                }
                if (rawModel.keys.contains('PostRotation')){
                  node["postRotation"] = rawModel["PostRotation"]["value"];
                }

                layerCurveNodes.add(node);
              }

              if (i < layerCurveNodes.length && layerCurveNodes[i] != null){
                layerCurveNodes[i][curveNode["attr"]] = curveNode;
              }
            } 
            else if (curveNode['curves']?['morph'] != null) {
              if (layerCurveNodes[i] == null) {
                final deformerID =
                    connections?[child["ID"]].parents.filter((parent) {
                  return parent.relationship != null;
                })[0].ID;

                final morpherID = connections?[deformerID].parents[0].ID;
                final geoID = connections?[morpherID].parents[0].ID;

                // assuming geometry is not used in more than one model
                final modelID = connections?[geoID].parents[0].ID;

                final rawModel = _fbxTree?.objects?["Model"][modelID];

                final node = {
                  "modelName": rawModel.attrName
                      ? PropertyBinding.sanitizeNodeName(rawModel.attrName)
                      : '',
                  "morphName": _fbxTree?.objects?["Deformer"][deformerID].attrName,
                };

                layerCurveNodes[i] = node;
              }

              layerCurveNodes[i][curveNode.attr] = curveNode;
            }
          }
        });

        layersMap[int.parse(nodeID.toString())] = layerCurveNodes;
      }
    }

    return layersMap;
  }

  // parse nodes in _FBXTree.Objects.AnimationStack. These are the top level node in the animation
  // hierarchy. Each Stack node will be used to create a AnimationClip
  parseAnimStacks(layersMap) {
    final rawStacks = _fbxTree?.objects?["AnimationStack"];

    // connect the stacks (clips) up to the layers
    final rawClips = {};

    for (final nodeID in rawStacks.keys) {
      final children = connections?[int.parse(nodeID.toString())]["children"];

      if (children.length > 1) {
        // it seems like stacks will always be associated with a single layer. But just in case there are files
        // where there are multiple layers per stack, we'll display a warning
        console.warning('FBXLoader: Encountered an animation stack with multiple layers, this is currently not supported. Ignoring subsequent layers.');
      }

      final layer = layersMap[children[0]["ID"]];

      rawClips[nodeID] = {
        "name": rawStacks[nodeID]["attrName"],
        "layer": layer,
      };
    }

    return rawClips;
  }

  AnimationClip addClip(rawClip) {
    final tracks = [];

    final scope = this;
    rawClip["layer"].forEach((rawTracks) {
      tracks.addAll(scope.generateTracks(rawTracks));
    });
    return AnimationClip(rawClip["name"], -1, List<KeyframeTrack>.from(tracks));
  }

  generateTracks(Map rawTracks) {
    final tracks = [];

    final initialPositionVector3 = Vector3();
    final initialRotationQuaternion = Quaternion();
    final initialScaleVector3 = Vector3();

    if (rawTracks["transform"] != null){
      rawTracks["transform"].decompose(initialPositionVector3,
          initialRotationQuaternion, initialScaleVector3);
    }

    final initialPosition = initialPositionVector3.copyIntoArray();
    final initialRotation = Euler()
        .setFromQuaternion(initialRotationQuaternion, RotationOrders.fromString(rawTracks["eulerOrder"]))
        .toArray();
    final initialScale = initialScaleVector3.copyIntoArray();

    if (rawTracks["T"] != null && rawTracks["T"]["curves"].keys.length > 0) {
      final positionTrack = _generateVectorTrack(rawTracks["modelName"],
          rawTracks["T"]["curves"], initialPosition, 'position');
      if (positionTrack != null) tracks.add(positionTrack);
    }
    if (rawTracks["R"]?["curves"]?.keys != null && rawTracks["R"]["curves"].keys.isNotEmpty) {
      final rotationTrack = generateRotationTrack(
        rawTracks["modelName"],
        rawTracks["R"]["curves"],
        initialRotation,
        rawTracks["preRotation"],
        rawTracks["postRotation"],
        rawTracks["eulerOrder"]
      );
      //if (rotationTrack != null) 
        tracks.add(rotationTrack);
    }
    if (rawTracks["S"]?["curves"]?.keys != null && rawTracks["S"]["curves"].keys.isNotEmpty) {
      final scaleTrack = _generateVectorTrack(rawTracks["modelName"],
          rawTracks["S"]["curves"], initialScale, 'scale');
      if (scaleTrack != null) tracks.add(scaleTrack);
    }

    if (rawTracks["DeformPercent"] != null) {
      final morphTrack = generateMorphTrack(rawTracks);
      if (morphTrack != null) tracks.add(morphTrack);
    }

    return tracks;
  }

  VectorKeyframeTrack? _generateVectorTrack(String modelName, Map curves, initialValue, type) {
    final times = _getTimesForAllAxes(curves);
    final values = _getKeyframeTrackValues(times, curves, initialValue);

    return VectorKeyframeTrack('$modelName.$type', times, values);
  }

  QuaternionKeyframeTrack generateRotationTrack(String modelName, Map curves, List<num> initialValue, preRotation, postRotation, eulerOrder) {
    if (curves["x"] != null) {
      interpolateRotations(curves["x"]);
      curves["x"]["values"] = curves["x"]["values"].map((double v) => v.toRad()).toList();
    }

    if (curves["y"] != null) {
      interpolateRotations(curves["y"]);
      curves["y"]["values"] = curves["y"]["values"]
          .map((double v) => v.toRad())
          .toList();
    }

    if (curves["z"] != null) {
      interpolateRotations(curves["z"]);
      curves["z"]["values"] = curves["z"]["values"]
          .map((double v) => v.toRad())
          .toList();
    }

    final times = _getTimesForAllAxes(curves);
    final values = _getKeyframeTrackValues(times, curves, initialValue);

    Quaternion? preRotationQuaternion;

    if (preRotation != null) {
      preRotation =
          preRotation.map((v) => (v as double).toRad()).toList();
      preRotation.add(eulerOrder);

      if (preRotation.length == 4 && RotationOrders.fromString(preRotation[3]).index >= 0) {
        preRotation[3] = RotationOrders.fromString(preRotation[3]).index.toDouble();
      }

      final preRotationEuler =
          Euler().fromArray(List<double>.from(preRotation));
      preRotationQuaternion = Quaternion().setFromEuler(preRotationEuler);
    }

    if (postRotation != null) {
      postRotation =
          postRotation.map((v) => v.toRad()).toList();
      postRotation.push(eulerOrder);

      postRotation = Euler().fromArray(postRotation);
      postRotation = Quaternion().setFromEuler(postRotation).invert();
    }

    final quaternion = Quaternion();
    final euler = Euler();

    List<double> quaternionValues =
        List<double>.filled(((values.length / 3) * 4).toInt(), 0.0);

    for (int i = 0; i < values.length; i += 3) {
      euler.set(values[i].toDouble(), values[i + 1].toDouble(), values[i + 2].toDouble(), RotationOrders.fromString(eulerOrder));

      quaternion.setFromEuler(euler);

      if (preRotationQuaternion != null){
        quaternion.premultiply(preRotationQuaternion);
      }
      if (postRotation != null) quaternion.multiply(postRotation);

      quaternion.toArray(quaternionValues, ((i / 3) * 4).toInt());
    }

    return QuaternionKeyframeTrack(
        '$modelName.quaternion', times, quaternionValues);
  }

  NumberKeyframeTrack? generateMorphTrack(rawTracks) {
    if(rawTracks == null) return null;
    final curves = rawTracks.DeformPercent.curves.morph;
    final values = curves.values.map((val) {
      return val / 100;
    }).toList();

    final morphNum = sceneGraph?.getObjectByName(rawTracks.modelName)?.morphTargetDictionary?[rawTracks.morphName];

    return NumberKeyframeTrack(
        '${rawTracks.modelName}.morphTargetInfluences[$morphNum]',
        curves.times,
        values);
  }

  // For all animated objects, times are defined separately for each axis
  // Here we'll combine the times into one sorted array without duplicates
  List<num> _getTimesForAllAxes(Map curves) {
    List<num> times = [];

    // first join together the times for each axis, if defined
    if (curves["x"] != null) times.addAll(List<num>.from(curves["x"]["times"]));
    if (curves["y"] != null) times.addAll(List<num>.from(curves["y"]["times"]));
    if (curves["z"] != null) times.addAll(List<num>.from(curves["z"]["times"]));

    // then sort them
    times.sort((a, b) {
      return a - b > 0 ? 1 : -1;
    });

    // and remove duplicates
    if (times.length > 1) {
      int targetIndex = 1;
      num lastValue = times[0];
      for (int i = 1; i < times.length; i++) {
        final currentValue = times[i];
        if (currentValue != lastValue) {
          times[targetIndex] = currentValue;
          lastValue = currentValue;
          targetIndex++;
        }
      }

      times = times.sublist(0, targetIndex);
    }

    return times;
  }

  List<num> _getKeyframeTrackValues(List<num> times, Map curves, List<num> initialValue) {
    final prevValue = initialValue;

    List<num> values = [];

    int xIndex = -1;
    int yIndex = -1;
    int zIndex = -1;

    //times.forEach((time) {
    for(num time in times){
      if (curves["x"] != null){
        xIndex = curves["x"]["times"].toList().indexOf(time);
      }
      if (curves["y"] != null){
        yIndex = curves["y"]["times"].toList().indexOf(time);
      }
      if (curves["z"] != null){
        zIndex = curves["z"]["times"].toList().indexOf(time);
      }

      // if there is an x value defined for this frame, use that
      if (xIndex != -1) {
        final xValue = curves["x"]["values"][xIndex];
        values.add(xValue);
        prevValue[0] = xValue;
      } else {
        // otherwise use the x value from the previous frame
        values.add(prevValue[0]);
      }

      if (yIndex != -1) {
        final yValue = curves["y"]["values"][yIndex];
        values.add(yValue);
        prevValue[1] = yValue;
      } else {
        values.add(prevValue[1]);
      }

      if (zIndex != -1) {
        final zValue = curves["z"]["values"][zIndex];
        values.add(zValue);
        prevValue[2] = zValue;
      } else {
        values.add(prevValue[2]);
      }
    }

    return values;
  }

  // Rotations are defined as Euler angles which can have values  of any size
  // These will be converted to quaternions which don't support values greater than
  // PI, so we'll interpolate large rotations
  void interpolateRotations(Map<String,dynamic> curve) {
    for (int i = 1; i < curve["values"].length; i++) {
      final initialValue = curve["values"][i - 1];
      final valuesSpan = curve["values"][i] - initialValue;

      final absoluteSpan = valuesSpan.abs();

      if (absoluteSpan >= 180) {
        final numSubIntervals = absoluteSpan / 180;

        final step = valuesSpan / numSubIntervals;
        num nextValue = initialValue + step;

        final initialTime = curve["times"][i - 1];
        final timeSpan = curve["times"][i] - initialTime;
        final interval = timeSpan / numSubIntervals;
        num nextTime = initialTime + interval;

        final interpolatedTimes = [];
        final interpolatedValues = [];

        while (nextTime < curve["times"][i]) {
          interpolatedTimes.add(nextTime);
          nextTime += interval;

          interpolatedValues.add(nextValue);
          nextValue += step;
        }

        curve["times"] = _inject(List<double>.from(curve["times"]), i, List<double>.from(interpolatedTimes));
        curve["values"] = _inject(List<double>.from(curve["values"]), i, List<double>.from(interpolatedValues));
      }
    }
  }
}

// parse an FBX file in ASCII format
class _TextParser {
  late int currentIndent;
  late List nodeStack;
  late dynamic currentProp;
  late _FBXTree allNodes;
  late String currentPropName;

  getPrevNode() {
    return nodeStack.isEmpty?{}:nodeStack[currentIndent - 2];
  }

  getCurrentNode() {
    return nodeStack.isEmpty?{}:nodeStack[currentIndent - 1];
  }

  getCurrentProp() {
    return currentProp;
  }

  void pushStack(node) {
    nodeStack.add(node);
    currentIndent += 1;
  }

  void popStack() {
    nodeStack.removeLast();
    currentIndent -= 1;
  }

  void setCurrentProp(val, String name) {
    currentProp = val;
    currentPropName = name;
  }

  _FBXTree parse(String text) {
    currentIndent = 0;

    allNodes = _FBXTree();
    nodeStack = [];
    currentProp = [];
    currentPropName = '';

    final scope = this;

    final split = text.split(RegExp(r'[\r\n]+'));
    split.asMap().forEach((i, line) {
      final matchComment = RegExp(r"^[\s\t]*;").hasMatch(line);
      final matchEmpty = RegExp(r"^[\s\t]*$").hasMatch(line);

      if (matchComment || matchEmpty) return;

      final matchBeginning = RegExp('\t{${scope.currentIndent}}(\\w+):(.*){').allMatches(line);// line.startsWith();
      final matchProperty = RegExp('\t{${scope.currentIndent}}(\\w+):[\\s\\t\\r\\n](.*)').allMatches(line);//line.contains();
      final matchEnd = line.contains(RegExp('^\\t{${scope.currentIndent - 1}}}'));
      
      if (matchBeginning.isNotEmpty) {
        scope.parseNodeBegin(line, matchBeginning.toList());
      } 
      else if (matchProperty.isNotEmpty) {
        scope.parseNodeProperty(line, matchProperty.toList(), split[++i]);
      } 
      else if (matchEnd) {
        scope.popStack();
      } 
      else if (RegExp(r"^[^\s\t}]").hasMatch(line)) {
        // large arrays are split over multiple lines terminated with a ',' character
        // if this is encountered the line needs to be joined to the previous line
        scope.parseNodePropertyContinued(line);
      }
    });

    return allNodes;
  }

  void parseNodeBegin(String line, List<RegExpMatch> property) {
    final nodeName = property.first.group(1)!
        .trim()
        .replaceFirst(RegExp(r'^"'), '')
        .replaceAll(RegExp(r'"$'), '');

    final nodeAttrs = property.first.group(2)!.split(',').map((attr) {
      return attr
          .trim()
          .replaceFirst(RegExp(r'^"'), '')
          .replaceAll(RegExp(r'"$'), '');
    }).toList();

    Map<String, dynamic> node = {"name": nodeName};
    final _NodeAttr attrs = parseNodeAttr(nodeAttrs);

    Map currentNode = getCurrentNode();

    // a top node
    if (currentIndent == 0) {
      allNodes.add(nodeName, node);
    } 
    else {
      // a subnode

      // if the subnode already exists, _append it
      if (currentNode.keys.contains(nodeName)) {
        // special case Pose needs PoseNodes as an array
        if (nodeName == 'PoseNode') {
          currentNode["PoseNode"].add(node);
        } 
        else if (currentNode[nodeName]['id'] != null) {
          currentNode[nodeName] = {};
          currentNode[nodeName][currentNode[nodeName]['id']] =
              currentNode[nodeName];
        }
        if (attrs.id != null) currentNode[nodeName][attrs.id] = node;
      } 
      else if (attrs.id is num) {
        currentNode[nodeName] = {};
        currentNode[nodeName][attrs.id] = node;
      } 
      else if (nodeName != 'Properties70') {
        if (nodeName == 'PoseNode'){
          currentNode[nodeName] = [node];
        }
        else{
          currentNode[nodeName] = node;
        }
      }
    }

    if (attrs.id is num) node["id"] = attrs.id;
    if (attrs.name != '') node["attrName"] = attrs.name;
    if (attrs.type != '') node["attrType"] = attrs.type;

    pushStack(node);
  }

  _NodeAttr parseNodeAttr(List<String> attrs) {
    int? id = int.tryParse(attrs[0]);

    // if (id == null && attrs[0] != '') {
    //   id = attrs[0];
    // }

    String name = '', type = '';

    if (attrs.length > 1) {
      name = attrs[1].replaceFirst(RegExp(r'^(\w+)::'), '');
    }
    if(attrs.length > 2){
      type = attrs[2];
    }
    return _NodeAttr(id: id, name: name, type: type);
  }

  void parseNodeProperty(String line, List<RegExpMatch> property, String contentLine) {
    final regExp = RegExp(r'^"');
    final regExp2 = RegExp(r'"$');

    String propName =
        property.first.group(1)!.replaceFirst(regExp, '').replaceFirst(regExp2, '').trim();
    String propValue =
        property.first.group(2)!.replaceFirst(regExp, '').replaceFirst(regExp2, '').trim();

    // for special case: base64 image data follows "Content: ," line
    //	Content: ,
    //	 "/9j/4RDaRXhpZgAATU0A..."
    if (propName == 'Content' && propValue == ',') {
      propValue = contentLine
          .replaceAll(RegExp(r'"'), '')
          .replaceFirst(RegExp(r',$'), '')
          .trim();
    }

    final currentNode = getCurrentNode();
    final parentName = currentNode['name'];

    if (parentName == 'Properties70') {
      parseNodeSpecialProperty(line, propName, propValue);
      return;
    }

    // Connections
    if (propName == 'C') {
      final connProps = propValue.split(',')..removeAt(0);//..removeRange(1,propValue.length);
      final from = int.parse(connProps[0]);
      final to = int.parse(connProps[1]);
      List<String> rest = propValue.split(',');
      rest = rest..removeRange(3, rest.length);

      rest = rest.map((elem) {
        return elem.trim().replaceFirst(RegExp(r'"'), '');
      }).toList();

      propName = 'connections';
      propValue = '$from, $to';
      _append(propValue, rest);

      if (currentNode[propName] == null) {
        currentNode[propName] = [];
      }
    }

    // Node
    if (propName == 'Node') currentNode['id'] = propValue;

    // connections
    if (currentNode.keys.contains(propName) && currentNode[propName] is List) {
      List pv = propValue.split(',');
      List<double> temp = [];
      for(int i = 0; i < pv.length;i++){
        temp.add(double.parse(pv[i]));
      }
      currentNode[propName].add(temp);
    } 
    else {
      if (propName != 'a'){
        currentNode[propName] = propValue;
      }
      else{
        currentNode['a'] = propValue;
      }
    }

    setCurrentProp(currentNode, propName);

    // convert string to array, unless it ends in ',' in which case more will be added to it
    if (propName == 'a' && propValue != ',') {
      currentNode['a'] = _parseNumberArray(propValue);
    }
  }

  void parseNodePropertyContinued(String line) {
    final currentNode = getCurrentNode();
    if(currentNode['a'] == null){
      currentNode['a'] = line;
    }
    else{
      currentNode['a'] += line;
    }

    // if the line doesn't end in ',' we have reached the end of the property value
    // so convert the string to an array
    if (!line.endsWith(',')) {
      currentNode['a'] = _parseNumberArray(currentNode['a']);
    }
  }

  // parse "Property70"
  void parseNodeSpecialProperty(String line, String propName, String propValue) {
    // split this
    // P: "Lcl Scaling", "Lcl Scaling", "", "A",1,1,1
    // into array like below
    // ["Lcl Scaling", "Lcl Scaling", "", "A", "1,1,1" ]
    final List<String> props = propValue.split('",').map((prop) {
      return prop.trim()
        .replaceAll(RegExp(r'^\"'), '')
        .replaceAll(RegExp(r'\s'), '_');
    }).toList();

    final innerPropName = props[0];
    final innerPropType1 = props[1];
    final innerPropType2 = props[2];
    final innerPropFlag = props[3];
    dynamic innerPropValue = props[4];

    // cast values where needed, otherwise leave as strings
    switch (innerPropType1) {
      case 'int':
      case 'enum':
      case 'bool':
      case 'ULongLong':
      case 'double':
      case 'Number':
      case 'FieldOfView':
        innerPropValue = double.parse(innerPropValue);
        break;

      case 'Color':
      case 'ColorRGB':
      case 'Vector3D':
      case 'Lcl_Translation':
      case 'Lcl_Rotation':
      case 'Lcl_Scaling':
        innerPropValue = _parseNumberArray(innerPropValue);
        break;
    }

    // CAUTION: these props must _append to parent's parent
    getPrevNode()[innerPropName] = {
      'type': innerPropType1,
      'type2': innerPropType2,
      'flag': innerPropFlag,
      'value': innerPropValue
    };

    setCurrentProp(getPrevNode(), innerPropName);
  }
}

// Parse an FBX file in Binary format
class _BinaryParser {
  _FBXTree parse(Uint8List buffer) {
    final reader = _BinaryReader(buffer);
    reader.skip(23); // skip magic 23 bytes

    final version = reader.getUint32();

    if (version < 6400) {
      throw ('FBXLoader: FBX version not supported, FileVersion: $version');
    }

    final allNodes = _FBXTree();

    while (!endOfContent(reader)) {
      final node = parseNode(reader, version);
      if (node != null) allNodes.add(node["name"], node);
    }
    return allNodes;
  }

  // Check if reader has reached the end of content.
  bool endOfContent(_BinaryReader reader) {
    // footer size: 160bytes + 16-byte alignment padding
    // - 16bytes: magic
    // - padding til 16-byte alignment (at least 1byte?)
    //	(seems like some exporters embed fixed 15 or 16bytes?)
    // - 4bytes: magic
    // - 4bytes: version
    // - 120bytes: zero
    // - 16bytes: magic
    if (reader.size() % 16 == 0) {
      return ((reader.getOffset() + 160 + 16) & ~0xf) >= reader.size();
    } else {
      return reader.getOffset() + 160 + 16 >= reader.size();
    }
  }

  // recursively parse nodes until the end of the file is reached
  Map<String, dynamic>? parseNode(_BinaryReader reader, version) {
    Map<String, dynamic> node = {};

    // The first three data sizes depends on version.
    final endOffset = (version >= 7500) ? reader.getUint64() : reader.getUint32();
    final numProperties =
        (version >= 7500) ? reader.getUint64() : reader.getUint32();

    (version >= 7500)
        ? reader.getUint64()
        : reader.getUint32(); // the returned propertyListLen is not used

    final nameLen = reader.getUint8();
    final name = reader.getString(nameLen);

    // Regards this node as NULL-record if endOffset is zero
    if (endOffset == 0) return null;

    final propertyList = [];

    for (int i = 0; i < numProperties; i++) {
      propertyList.add(parseProperty(reader));
    }

    // Regards the first three elements in propertyList as id, attrName, and attrType
    final id = propertyList.isNotEmpty ? propertyList[0] : '';
    final attrName = propertyList.length > 1 ? propertyList[1] : '';
    final attrType = propertyList.length > 2 ? propertyList[2] : '';

    // check if this node represents just a single property
    // like (name, 0) set or (name2, [0, 1, 2]) set of {name: 0, name2: [0, 1, 2]}
    node["singleProperty"] =
        (numProperties == 1 && reader.getOffset() == endOffset) ? true : false;

    while (endOffset > reader.getOffset()) {
      final subNode = parseNode(reader, version);

      if (subNode != null) parseSubNode(name, node, subNode);
    }

    node["propertyList"] = propertyList; // raw property list used by parent

    if (id is num) node["id"] = id;
    if (attrName != '') node["attrName"] = attrName;
    if (attrType != '') node["attrType"] = attrType;
    if (name != '') node["name"] = name;

    return node;
  }

  void parseSubNode(name, Map<String, dynamic> node, Map<String, dynamic> subNode) {
    // special case: child node is single property
    if (subNode["singleProperty"] == true) {
      final value = subNode["propertyList"][0];

      if (value is List) {
        node[subNode["name"]] = subNode;

        subNode["a"] = value;
      } else {
        node[subNode["name"]] = value;
      }
    } else if (name == 'Connections' && subNode["name"] == 'C') {
      final array = [];

      subNode["propertyList"].asMap().forEach((i, property) {
        // first Connection is FBX type (OO, OP, etc.). We'll discard these
        if (i != 0) array.add(property);
      });

      if (node["connections"] == null) {
        node["connections"] = [];
      }

      node["connections"].add(array);
    } else if (subNode["name"] == 'Properties70') {
      final keys = subNode.keys;

      //keys.forEach((key) {
      for(String key in keys){
        node[key] = subNode[key];
      }
    } else if (name == 'Properties70' && subNode["name"] == 'P') {
      String innerPropName = subNode["propertyList"][0];
      String innerPropType1 = subNode["propertyList"][1];
      final String innerPropType2 = subNode["propertyList"][2];
      final String innerPropFlag = subNode["propertyList"][3];
      dynamic innerPropValue;

      if (innerPropName.indexOf('Lcl ') == 0){
        innerPropName = innerPropName.replaceFirst('Lcl ', 'Lcl_');
      }
      if (innerPropType1.indexOf('Lcl ') == 0){
        innerPropType1 = innerPropType1.replaceFirst('Lcl ', 'Lcl_');
      }

      if (innerPropType1 == 'Color' ||
          innerPropType1 == 'ColorRGB' ||
          innerPropType1 == 'Vector' ||
          innerPropType1 == 'Vector3D' ||
          innerPropType1.indexOf('Lcl_') == 0) {
        innerPropValue = [
          subNode["propertyList"][4],
          subNode["propertyList"][5],
          subNode["propertyList"][6]
        ];
      } else {
        if (subNode["propertyList"].length > 4) {
          innerPropValue = subNode["propertyList"][4];
        }
      }

      // this will be copied to parent, see above
      node[innerPropName] = {
        'type': innerPropType1,
        'type2': innerPropType2,
        'flag': innerPropFlag,
        'value': innerPropValue
      };
    } else if (node[subNode["name"]] == null) {
      if (subNode["id"] is num) {
        node[subNode["name"]] = {};
        node[subNode["name"]][subNode["id"]] = subNode;
      } else {
        node[subNode["name"]] = subNode;
      }
    } else {
      if (subNode["name"] == 'PoseNode') {
        if (node[subNode["name"]] is! List) {
          node[subNode["name"]] = [node[subNode["name"]]];
        }

        node[subNode["name"]].add(subNode);
      } else if (node[subNode["name"]][subNode["id"]] == null) {
        if (subNode["id"] != null) {
          node[subNode["name"]][subNode["id"]] = subNode;
        }
      }
    }
  }

  dynamic parseProperty(_BinaryReader reader) {
    final type = reader.getString(1);
    late int length;

    switch (type) {
      case 'C':
        return reader.getBoolean();

      case 'D':
        return reader.getFloat64();

      case 'F':
        return reader.getFloat32();

      case 'I':
        return reader.getInt32();

      case 'L':
        return reader.getInt64();

      case 'R':
        length = reader.getUint32();
        return reader.getArrayBuffer(length);

      case 'S':
        length = reader.getUint32();
        return reader.getString(length);

      case 'Y':
        return reader.getInt16();

      case 'b':
      case 'c':
      case 'd':
      case 'f':
      case 'i':
      case 'l':
        final arrayLength = reader.getUint32();
        final encoding = reader.getUint32(); // 0: non-compressed, 1: compressed
        final compressedLength = reader.getUint32();

        if (encoding == 0) {
          switch (type) {
            case 'b':
            case 'c':
              return reader.getBooleanArray(arrayLength);

            case 'd':
              return reader.getFloat64Array(arrayLength);

            case 'f':
              return reader.getFloat32Array(arrayLength);

            case 'i':
              return reader.getInt32Array(arrayLength);

            case 'l':
              return reader.getInt64Array(arrayLength);
          }
        }

        // https://pub.dev/packages/archive
        // use archive replace fflate.js
        // final data = fflate.unzlibSync( Uint8List( reader.getArrayBuffer( compressedLength ) ) ); // eslint-disable-line no-undef
        //final data = const ZLibDecoder().decodeBytes(reader.getArrayBuffer(compressedLength), verify: true);
        final data = ZLibDecoder().convert(reader.getArrayBuffer(compressedLength));
        final reader2 = _BinaryReader(data);

        switch (type) {
          case 'b':
          case 'c':
            return reader2.getBooleanArray(arrayLength);

          case 'd':
            return reader2.getFloat64Array(arrayLength);

          case 'f':
            return reader2.getFloat32Array(arrayLength);

          case 'i':
            return reader2.getInt32Array(arrayLength);

          case 'l':
            return reader2.getInt64Array(arrayLength);
        }
        break;

      default:
        throw ('FBXLoader: Unknown property type $type');
    }
  }
}

class _BinaryReader {
  late int offset;
  late Uint8List dv;
  late bool littleEndian;

  _BinaryReader(buffer, [littleEndian]) {
    dv = buffer;
    offset = 0;
    this.littleEndian = (littleEndian != null) ? littleEndian : true;
  }

  int getOffset() {
    return offset;
  }

  int size() {
    return dv.buffer.lengthInBytes;
  }

  void skip(int length) {
    offset += length;
  }

  // seems like true/false representation depends on exporter.
  // true: 1 or 'Y'(=0x59), false: 0 or 'T'(=0x54)
  // then sees LSB.
  bool getBoolean() {
    return (getUint8() & 1) == 1;
  }

  List<bool> getBooleanArray(int size) {
    final List<bool> a = [];

    for (int i = 0; i < size; i++) {
      a.add(getBoolean());
    }

    return a;
  }

  int getUint8() {
    final value = dv.buffer.asByteData().getUint8(offset);
    offset += 1;
    return value;
  }

  int getInt16() {
    final value = dv
        .buffer
        .asByteData()
        .getInt16(offset, littleEndian ? Endian.little : Endian.big);
    offset += 2;
    return value;
  }

  int getInt32() {
    final value = dv
        .buffer
        .asByteData()
        .getInt32(offset, littleEndian ? Endian.little : Endian.big);
    offset += 4;
    return value;
  }

  List<int> getInt32Array(size) {
    final List<int> a = [];

    for (int i = 0; i < size; i++) {
      a.add(getInt32());
    }

    return a;
  }

  int getUint32() {
    final value = dv
        .buffer
        .asByteData()
        .getUint32(offset, littleEndian ? Endian.little : Endian.big);
    offset += 4;
    return value;
  }

  // JavaScript doesn't support 64-bit integer so calculate this here
  // 1 << 32 will return 1 so using multiply operation instead here.
  // There's a possibility that this method returns wrong value if the value
  // is out of the range between Number.MAX_SAFE_INTEGER and Number.MIN_SAFE_INTEGER.
  // TODO: safely handle 64-bit integer
  int getInt64() {
    int low, high;

    if (littleEndian) {
      low = getUint32();
      high = getUint32();
    } else {
      high = getUint32();
      low = getUint32();
    }

    // calculate negative value
    if ((high & 0x80000000) > 0) {
      high = ~high & 0xFFFFFFFF;
      low = ~low & 0xFFFFFFFF;

      if (low == 0xFFFFFFFF) high = (high + 1) & 0xFFFFFFFF;

      low = (low + 1) & 0xFFFFFFFF;

      return -(high * 0x100000000 + low);
    }

    return high * 0x100000000 + low;
  }

  List<int> getInt64Array(int size) {
    final List<int> a = [];

    for (int i = 0; i < size; i++) {
      a.add(getInt64());
    }

    return a;
  }

  // Note: see getInt64() comment
  int getUint64() {
    late int low;
    late int high;

    if (littleEndian) {
      low = getUint32();
      high = getUint32();
    } else {
      high = getUint32();
      low = getUint32();
    }

    return high * 0x100000000 + low;
  }

  double getFloat32() {
    final value = dv.buffer.asByteData().getFloat32(
        offset, littleEndian ? Endian.little : Endian.big);
    offset += 4;
    return value;
  }

  List<double> getFloat32Array(int size) {
    final List<double> a = [];

    for (int i = 0; i < size; i++) {
      a.add(getFloat32());
    }

    return a;
  }

  double getFloat64() {
    final value = dv.buffer.asByteData().getFloat64(offset, littleEndian ? Endian.little : Endian.big);
    offset += 8;
    return value;
  }

  List<double> getFloat64Array(int size) {
    final List<double> a = [];

    for (int i = 0; i < size; i++) {
      a.add(getFloat64());
    }

    return a;
  }

  Uint8List getArrayBuffer(int size) {
    final value = dv.sublist(offset, offset + size);
    offset += size;
    return value;
  }

  String getString(int size) {
    // note: safari 9 doesn't support Uint8List.indexOf; create intermediate array instead
    List<int> a = List<int>.filled(size, 0);

    for (int i = 0; i < size; i++) {
      a[i] = getUint8();
    }

    final nullByte = a.indexOf(0);
    if (nullByte >= 0) a = a.sublist(0, nullByte);

    return LoaderUtils.decodeText(a);
  }
}

// _FBXTree holds a representation of the FBX data, returned by the _TextParser ( FBX ASCII format)
// and _BinaryParser( FBX Binary format)
class _FBXTree {
  Map<String, dynamic> data = {};

  add(key, val) {
    data[key] = val;
  }

  Map<String, dynamic>? get objects => data["Objects"];
  Map<String, dynamic>? get connections => data["Connections"];
  Map<String, dynamic>? get globalSettings => data["GlobalSettings"];
}

// ************** UTILITY FUNCTIONS **************

bool _isFbxFormatBinary(Uint8List buffer) {
  String correct = 'Kaydara\u0020FBX\u0020Binary\u0020\u0020\0';
  String str = _convertArrayBufferToString(buffer, 0, correct.length);

  return buffer.lengthInBytes >= correct.length &&
      "Kaydara FBX Binary" == str.substring(0, 18).trim();
}

bool _isFbxFormatASCII(String text) {
  final correct = [
    'K',
    'a',
    'y',
    'd',
    'a',
    'r',
    'a',
    '\\',
    'F',
    'B',
    'X',
    '\\',
    'B',
    'i',
    'n',
    'a',
    'r',
    'y',
    '\\',
    '\\'
  ];

  int cursor = 0;

  String read(int offset) {
    final result = text[offset - 1];
    text = text.substring((cursor + offset).toInt()); //._slice( cursor + offset );
    cursor++;
    return result;
  }

  for (int i = 0; i < correct.length; ++i) {
    final num = read(1);
    if (num == correct[i]) {
      return false;
    }
  }

  return true;
}

int _getFbxVersion(String text) {
  final versionRegExp = RegExp(r"FBXVersion: (\d+)");
  final match = versionRegExp.firstMatch(text);

  if (versionRegExp.hasMatch(text)) {
    final version = int.parse(match!.group(1)!);
    return version;
  }

  throw ('FBXLoader: Cannot find the version number for the file given.');
}

// Converts FBX ticks into real time seconds.
num _convertFBXTimeToSeconds(int time) {
  return time / 46186158000;
}

final dataArray = [];

// extracts the data from the correct position in the FBX array based on indexing type
_getData(int polygonVertexIndex, int polygonIndex, int vertexIndex, infoObject) {
  int index = 0;

  switch (infoObject["mappingType"]) {
    case 'ByPolygonVertex':
      index = polygonVertexIndex;
      break;
    case 'ByPolygon':
      index = polygonIndex;
      break;
    case 'ByVertice':
      index = vertexIndex;
      break;
    case 'AllSame':
      index = infoObject.indices[0];
      break;
    default:
      console.warning('FBXLoader: unknown attribute mapping type ${infoObject["mappingType"]}');
  }

  if (infoObject["referenceType"] == 'IndexToDirect'){
    index = infoObject["indices"][index];
  }

  final int from = (index * infoObject["dataSize"]).toInt();
  final to = from + infoObject["dataSize"];

  return _slice(dataArray, infoObject["buffer"], from, to);
}

final tempEuler = Euler();
final tempVec = Vector3();

// generate transformation from FBX transform data
// ref: https://help.autodesk.com/view/FBX/2017/ENU/?guid=__files_GUID_10CDD63C_79C1_4F2D_BB28_AD2BE65A02ED_htm
// ref: http://docs.autodesk.com/FBX/2014/ENU/FBX-SDK-Documentation/index.html?url=cpp_ref/_transformations_2main_8cxx-example.html,topicNumber=cpp_ref__transformations_2main_8cxx_example_htmlfc10a1e1-b18d-4e72-9dc0-70d0f1959f5e
Matrix4 _generateTransform(Map transformData) {
  final lTranslationM = Matrix4();
  final lPreRotationM = Matrix4();
  final lRotationM = Matrix4();
  final lPostRotationM = Matrix4();

  final lScalingM = Matrix4();
  final lScalingPivotM = Matrix4();
  final lScalingOffsetM = Matrix4();
  final lRotationOffsetM = Matrix4();
  final lRotationPivotM = Matrix4();

  final lParentGX = Matrix4();
  final lParentLX = Matrix4();
  final lGlobalT = Matrix4();

  final inheritType =
      (transformData["inheritType"] != null) ? transformData["inheritType"] : 0;

  if (transformData["translation"] != null){
    lTranslationM.setPositionFromVector3(tempVec.copyFromUnknown(transformData["translation"]));
  }
  if (transformData["preRotation"] != null) {
    List<double> array = List<double>.from(transformData["preRotation"]
        .map((e) => (e as double).toRad())
        .toList());
    array.add(RotationOrders.fromString(transformData["eulerOrder"]).index.toDouble());
    lPreRotationM.makeRotationFromEuler(tempEuler.fromArray(array));
  }

  if (transformData["rotation"] != null) {
    List<double> array = List<double>.from(transformData["rotation"]
        .map((e) => (e as double).toRad())
        .toList());
    array.add(RotationOrders
        .fromString(transformData["eulerOrder"]).index
        .toDouble());
    lRotationM.makeRotationFromEuler(tempEuler.fromArray(array));
  }

  if (transformData["postRotation"] != null) {
    List<double> array = List<double>.from(
        transformData["postRotation"].map((e) => (e as double).toRad()).toList());
    array.add(RotationOrders
        .values[transformData["eulerOrder"]].index
        .toDouble());
    lPostRotationM.makeRotationFromEuler(tempEuler.fromArray(array));
    lPostRotationM.invert();
  }

  if (transformData["scale"] != null){
    lScalingM.scaleByVector(tempVec.copyFromUnknown(transformData["scale"]));
  }

  // Pivots and offsets
  if (transformData["scalingOffset"] != null){
    lScalingOffsetM.setPositionFromVector3(tempVec.copyFromUnknown(transformData["scalingOffset"]));
  }
  if (transformData["scalingPivot"] != null){
    lScalingPivotM.setPositionFromVector3(tempVec.copyFromUnknown(transformData["scalingPivot"]));
  }
  if (transformData["rotationOffset"] != null){
    lRotationOffsetM.setPositionFromVector3(tempVec.copyFromUnknown(transformData["rotationOffset"]));
  }
  if (transformData["rotationPivot"] != null){
    lRotationPivotM.setPositionFromVector3(tempVec.copyFromUnknown(transformData["rotationPivot"]));
  }
  // parent transform
  if (transformData["parentMatrixWorld"] != null) {
    lParentLX.setFrom(transformData["parentMatrix"]);
    lParentGX.setFrom(transformData["parentMatrixWorld"]);
  }

  final lLRM = lPreRotationM.clone().multiply(lRotationM).multiply(lPostRotationM);
  // Global Rotation
  final lParentGRM = Matrix4();
  lParentGRM.extractRotation(lParentGX);

  // Global Shear*Scaling
  final lParentTM = Matrix4();
  lParentTM.copyPosition(lParentGX);

  final lParentGRSM = lParentTM.clone().invert().multiply(lParentGX);
  final lParentGSM = lParentGRM.clone().invert().multiply(lParentGRSM);
  final lLSM = lScalingM;

  final lGlobalRS = Matrix4();

  if (inheritType == 0) {
    lGlobalRS.setFrom(lParentGRM)
        .multiply(lLRM)
        .multiply(lParentGSM)
        .multiply(lLSM);
  } else if (inheritType == 1) {
    lGlobalRS.setFrom(lParentGRM)
        .multiply(lParentGSM)
        .multiply(lLRM)
        .multiply(lLSM);
  } else {
    final lParentLSM =
        Matrix4().scaleByVector(Vector3.zero().setFromMatrixScale(lParentLX));
    final lParentLSMInv = lParentLSM.clone().invert();
    final lParentGSMNoLocal = lParentGSM.clone().multiply(lParentLSMInv);

    lGlobalRS.setFrom(lParentGRM)
        .multiply(lLRM)
        .multiply(lParentGSMNoLocal)
        .multiply(lLSM);
  }

  final lRotationPivotMInv = lRotationPivotM.clone().invert();
  final lScalingPivotMInv = lScalingPivotM.clone().invert();
  // Calculate the local transform matrix
  Matrix4 lTransform = lTranslationM
      .clone()
      .multiply(lRotationOffsetM)
      .multiply(lRotationPivotM)
      .multiply(lPreRotationM)
      .multiply(lRotationM)
      .multiply(lPostRotationM)
      .multiply(lRotationPivotMInv)
      .multiply(lScalingOffsetM)
      .multiply(lScalingPivotM)
      .multiply(lScalingM)
      .multiply(lScalingPivotMInv);

  final lLocalTWithAllPivotAndOffsetInfo = Matrix4().copyPosition(lTransform);

  final lGlobalTranslation =
      lParentGX.clone().multiply(lLocalTWithAllPivotAndOffsetInfo);
  lGlobalT.copyPosition(lGlobalTranslation);

  lTransform = lGlobalT.clone().multiply(lGlobalRS);

  // from global to local
  lTransform.premultiply(lParentGX.invert());

  return lTransform;
}

// Returns the three.js intrinsic Euler order corresponding to FBX extrinsic Euler order
// ref: http://help.autodesk.com/view/FBX/2017/ENU/?guid=__cpp_ref_class_fbx_euler_html
String _getEulerOrder(int? order) {
  order = order ?? 0;

  final enums = [
    'ZYX', // -> XYZ extrinsic
    'YZX', // -> XZY extrinsic
    'XZY', // -> YZX extrinsic
    'ZXY', // -> YXZ extrinsic
    'YXZ', // -> ZXY extrinsic
    'XYZ', // -> ZYX extrinsic
    //'SphericXYZ', // not possible to support
  ];

  if (order == 6) {
    console.warning('FBXLoader: unsupported Euler Order: Spherical XYZ. Animations and rotations may be incorrect.');
    return enums[0];
  }

  return enums[order];
}

// Parses comma separated list of numbers and returns them an array.
// Used internally by the _TextParser
List<double> _parseNumberArray(String value) {
  final array = value.split(',').map((val) {
    return double.tryParse(val) ?? 0;
  }).toList();

  return array;
}

String _convertArrayBufferToString(Uint8List buffer, [int? from, int? to]) {
  from ??= 0;
  to ??= buffer.lengthInBytes;

  final str = LoaderUtils.decodeText(Uint8List.view(buffer.buffer, from, to).toList());

  return str;
}

void _append(a, b) {
  for (int i = 0, j = a.length, l = b.length; i < l; i++, j++) {
    a+= ', ${b[i]}';
  }
}

_slice(a, b, int from, num to) {
  for (int i = from, j = 0; i < to; i++, j++) {
    if (a.length == j) {
      a.add(b[i]);
    }
    else{
      a[j] = b[i];
    }
  }

  return a;
}

// _inject array a2 into array a1 at index
List<double> _inject(List<double> a1, int index, List<double> a2) {
  return a1.sublist(0, index)
    ..addAll(a2)
    ..addAll(a1.sublist(index));
}

int? _parseInt( v) {
  return int.tryParse(v.toString());
}

class _NodeAttr{
  _NodeAttr({
    this.id,
    this.name,
    this.type
  });

  int? id;
  String? name;
  String? type;
}