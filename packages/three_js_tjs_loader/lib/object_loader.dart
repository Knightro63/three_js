import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:three_js_curves/three_js_curves.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'material_loader.dart';
import 'buffer_geometry_loader.dart';

/// A loader for loading a JSON resource in the
/// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
/// 
/// This uses the [FileLoader] internally for loading files.
class ObjectLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a new [FontLoader].
  ObjectLoader([super.manager]){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }

  void _init(){
    _loader.setPath(path);
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<Object3D?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Object3D?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<Object3D?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Object3D?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<Object3D?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<Object3D?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  Future<Object3D?> _parse(Uint8List bytes) async {
    Map<String,dynamic> json = jsonDecode(String.fromCharCodes(bytes));
    final metadata = json['metadata'];

    if (metadata == null || metadata['type'] == null || metadata['type'].toLowerCase() == 'geometry') {
      console.warning('ObjectLoader: Can\'t load Object');
      return null;
    }

    final animations = parseAnimations(json['animations']);
    final shapes = parseShapes(json['shapes']);
    final geometries = parseGeometries(json['geometries'], shapes);

    final images = await parseImages(json['images'], null);

    final textures = parseTextures(json['textures'], images);
    final materials = parseMaterials(json['materials'], textures);

    final object = parseObject(json['object'], geometries, materials, textures, animations);
    final skeletons = parseSkeletons(json['skeletons'], object);

    bindSkeletons(object, skeletons);

    return object;
  }

  Map<String,Shape> parseShapes(json) {
    final Map<String,Shape> shapes = {};

    if (json != null) {
      for (int i = 0, l = json.length; i < l; i++) {
        final shape = Shape.fromJson(json[i]);
        shapes[shape.uuid] = shape;
      }
    }

    return shapes;
  }

  parseSkeletons(json, object) {
    final skeletons = {};
    final Map<String, Bone?> bones = {};

    // generate bone lookup table

    object.traverse((child) {
      if (child is Bone) bones[child.uuid] = child;
    });

    // create skeletons

    if (json != null) {
      for (int i = 0, l = json.length; i < l; i++) {
        final skeleton = Skeleton().fromJson(json[i], bones);

        skeletons[skeleton.uuid] = skeleton;
      }
    }

    return skeletons;
  }

  parseGeometries(json, shapes) {
    final geometries = {};

    if (json != null) {
      final bufferGeometryLoader = BufferGeometryLoader();

      for (int i = 0, l = json.length; i < l; i++) {
        late BufferGeometry geometry;
        Map<String, dynamic> data = json[i];

        switch (data["type"]) {
          case 'BufferGeometry':
          case 'InstancedBufferGeometry':
            geometry = bufferGeometryLoader.parseJson(data);
            break;
          case 'Geometry':
            console.error('ObjectLoader: The legacy Geometry type is no longer supported.');
            break;
          default:
            if (data["type"] == "PlaneGeometry") {
              geometry = PlaneGeometry.fromJson(data);
            } else if (data["type"] == "BoxGeometry") {
              geometry = BoxGeometry.fromJson(data);
            } else if (data["type"] == "CylinderGeometry") {
              geometry = CylinderGeometry.fromJson(data);
            } else if (data["type"] == "SphereGeometry") {
              geometry = SphereGeometry.fromJson(data);
            } else {
              throw ("THREE.ObjectLoader: Unsupported geometry type ${data["type"]}");
            }
        }

        geometry.uuid = data["uuid"];

        if (data["name"] != null) geometry.name = data["name"];
        if (data["userData"] != null) {
          geometry.userData = data["userData"];
        }

        geometries[data["uuid"]] = geometry;
      }
    }

    return geometries;
  }

  parseMaterials(json, textures) {
    final cache = {}; // MultiMaterial
    final materials = {};

    if (json != null) {
      final loader = MaterialLoader(null);
      loader.setTextures(textures);

      for (int i = 0, l = json.length; i < l; i++) {
        Map<String, dynamic> data = json[i];

        if (data["type"] == 'MultiMaterial') {
          // Deprecated

          final array = [];

          for (int j = 0; j < data["materials"].length; j++) {
            final material = data["materials"][j];

            if (cache[material.uuid] == null) {
              cache[material.uuid] = loader.parseJson(material);
            }

            array.add(cache[material.uuid]);
          }

          materials[data["uuid"]] = array;
        } else {
          if (cache[data["uuid"]] == null) {
            cache[data["uuid"]] = loader.parseJson(data);
          }

          materials[data["uuid"]] = cache[data["uuid"]];
        }
      }
    }

    return materials;
  }

  parseAnimations(json) {
    final animations = {};

    if (json != null) {
      for (int i = 0; i < json.length; i++) {
        final data = json[i];

        final clip = AnimationClip.parse(data);
        animations[clip.uuid] = clip;
      }
    }

    return animations;
  }

  parseImages(json, onLoad) async {
    final scope = this;
    final images = {};

    late ImageLoader loader;

    loadImage(url) async {
      scope.manager.itemStart(url);
      return await loader.unknown(url);
    }

    deserializeImage(image) async {
      if (image is String) {
        final url = image;

        final path =
            RegExp("^(//)|([a-z]+:(//)?)", caseSensitive: false).hasMatch(url)
                ? url
                : (scope.resourcePath ?? "") + url;

        return await loadImage(path);
      } else {
        if (image.data) {
          return {
            "data": getTypedArray(image.type, image.data),
            "width": image.width,
            "height": image.height
          };
        } else {
          return null;
        }
      }
    }

    if (json != null && json.length > 0) {
      final manager = LoadingManager(onLoad, null, null);

      loader = ImageLoader(manager);
      loader.setCrossOrigin(crossOrigin);

      for (int i = 0, il = json.length; i < il; i++) {
        Map<String, dynamic> image = json[i];
        final url = image["url"];

        if (url is List) {
          // load array of images e.g CubeTexture

          List imageArray = [];

          for (int j = 0, jl = url.length; j < jl; j++) {
            final currentUrl = url[j];

            final deserializedImage = await deserializeImage(currentUrl);

            if (deserializedImage != null) {
              imageArray.add(deserializedImage);

              // if ( deserializedImage is HTMLImageElement ) {

              // 	imageArray.push( deserializedImage );

              // } else {

              // 	// special case: handle array of data textures for cube textures

              // 	imageArray.push( new DataTexture( deserializedImage.data, deserializedImage.width, deserializedImage.height ) );

              // }

            }
          }

          images[image["uuid"]] = Source(imageArray);
        } else {
          // load single image

          final deserializedImage = await deserializeImage(image["url"]);

          if (deserializedImage != null) {
            images[image["uuid"]] = Source(deserializedImage);
          }
        }
      }
    }

    return images;
  }

  Map parseTextures(json, images) {
    parseConstant(value, type) {
      if (value is num) return value;
      console.warning('ObjectLoader.parseTexture: Constant should be in numeric form. $value');
      return type[value];
    }

    final textures = {};

    if (json != null) {
      for (int i = 0, l = json.length; i < l; i++) {
        Map<String, dynamic> data = json[i];

        if (data['image'] == null) {
          console.warning('ObjectLoader: No "image" specified for ${data["uuid"]}');
        }

        if (images[data["image"]] == null) {
          console.warning('ObjectLoader: Undefined image ${data["image"]}');
        }

        Texture texture;

        final source = images[data["image"]];
        final image = source.data;

        if (image is List) {
          texture = CubeTexture();
          if (image.length == 6) texture.needsUpdate = true;
        }
         else {
          if (image != null && image.data != null && image.url == null) {
            texture = DataTexture();
          } else {
            texture = Texture();
          }
          if (image != null) {
            texture.needsUpdate = true;
          } // textures can have null image data
        }

        texture.source = source;
        texture.uuid = data["uuid"];

        if (data["name"] != null) texture.name = data["name"];

        if (data["mapping"] != null) {
          texture.mapping = parseConstant(data["mapping"], textureMapping);
        }

        if (data["offset"] != null) texture.offset.copyFromArray(data["offset"]);
        if (data["repeat"] != null) texture.repeat.copyFromArray(data["repeat"]);
        if (data["center"] != null) texture.center.copyFromArray(data["center"]);
        if (data["rotation"] != null) texture.rotation = data["rotation"];

        if (data["wrap"] != null) {
          texture.wrapS = parseConstant(data["wrap"][0], textureWrapping);
          texture.wrapT = parseConstant(data["wrap"][1], textureWrapping);
        }

        if (data["format"] != null) texture.format = data["format"];
        if (data["type"] != null) texture.type = data["type"];
        if (data["colorSpace"] != null) texture.colorSpace = data["colorSpace"];

        if (data["minFilter"] != null) {
          texture.minFilter = parseConstant(data["minFilter"], textureFilter);
        }
        if (data["magFilter"] != null) {
          texture.magFilter = parseConstant(data["magFilter"], textureFilter);
        }
        if (data["anisotropy"] != null) texture.anisotropy = data["anisotropy"];

        if (data["flipY"] != null) texture.flipY = data["flipY"];

        if (data["premultiplyAlpha"] != null) {
          texture.premultiplyAlpha = data["premultiplyAlpha"];
        }
        if (data["unpackAlignment"] != null) {
          texture.unpackAlignment = data["unpackAlignment"];
        }
        if (data["userData"] != null) texture.userData = data["userData"];

        textures[data["uuid"]] = texture;
      }
    }

    return textures;
  }

  Object3D parseObject(
      Map<String, dynamic> data, geometries, materials, textures, animations) {
    dynamic object;

    getGeometry(name) {
      if (geometries[name] == null) {
        console.warning('ObjectLoader: Undefined geometry $name');
      }

      return geometries[name];
    }

    getMaterial(name) {
      if (name == null) return null;

      if (name is List) {
        final array = [];

        for (int i = 0, l = name.length; i < l; i++) {
          final uuid = name[i];

          if (materials[uuid] == null) {
            console.warning('ObjectLoader: Undefined material $uuid');
          }

          array.add(materials[uuid]);
        }

        return array;
      }

      if (materials[name] == null) {
        console.warning('ObjectLoader: Undefined material $name');
      }

      return materials[name];
    }

    getTexture(uuid) {
      if (textures[uuid] == null) {
        console.warning('ObjectLoader: Undefined texture $uuid');
      }

      return textures[uuid];
    }

    BufferGeometry geometry;
    Material material;

    switch (data["type"]) {
      case 'Scene':
        object = Scene();

        if (data["background"] != null) {
          if (data["background"] is int) {
            object.background = Color.fromHex32(data["background"]);
          } else {
            object.background = getTexture(data["background"]);
          }
        }

        if (data["environment"] != null) {
          object.environment = getTexture(data["environment"]);
        }

        if (data["fog"] != null) {
          if (data["fog"]["type"] == 'Fog') {
            object.fog = Fog(
                data["fog"]["color"], data["fog"]["near"], data["fog"]["far"]);
          } else if (data["fog"]["type"] == 'FogExp2') {
            object.fog = FogExp2(data["fog"]["color"], data["fog"]["density"]);
          }
        }

        break;

      case 'PerspectiveCamera':
        object = PerspectiveCamera(
            data["fov"], data["aspect"], data["near"], data["far"]);

        if (data["focus"] != null) object.focus = data["focus"];
        if (data["zoom"] != null) object.zoom = data["zoom"];
        if (data["filmGauge"] != null) object.filmGauge = data["filmGauge"];
        if (data["filmOffset"] != null) object.filmOffset = data["filmOffset"];
        if (data["view"] != null) {
          object.view = jsonDecode(jsonEncode(data["view"]));
        }

        break;

      case 'OrthographicCamera':
        object = OrthographicCamera(data["left"], data["right"], data["top"],
            data["bottom"], data["near"], data["far"]);

        if (data["zoom"] != null) object.zoom = data["zoom"];
        if (data["view"] != null) {
          object.view = jsonDecode(jsonEncode(data["view"]));
        }

        break;

      case 'AmbientLight':
        object = AmbientLight(data["color"], data["intensity"]);

        break;

      case 'DirectionalLight':
        object = DirectionalLight(data["color"], data["intensity"]);

        break;

      case 'PointLight':
        object = PointLight(
            data["color"], data["intensity"], data["distance"], data["decay"]);

        break;

      case 'RectAreaLight':
        object = RectAreaLight(
            data["color"], data["intensity"], data["width"], data["height"]);

        break;

      case 'SpotLight':
        object = SpotLight(data["color"], data["intensity"], data["distance"],
            data["angle"], data["penumbra"], data["decay"]);

        break;

      case 'HemisphereLight':
        object = HemisphereLight(
            data["color"], data["groundColor"], data["intensity"]);

        break;

      case 'LightProbe':
        object = LightProbe.fromJson(data);

        break;

      case 'SkinnedMesh':
        geometry = getGeometry(data["geometry"]);
        material = getMaterial(data["material"]);

        object = SkinnedMesh(geometry, material);

        if (data["bindMode"] != null) object.bindMode = data["bindMode"];
        if (data["bindMatrix"] != null) {
          object.bindMatrix.fromArray(data["bindMatrix"]);
        }
        if (data["skeleton"] != null) object.skeleton = data["skeleton"];

        break;

      case 'Mesh':
        geometry = getGeometry(data["geometry"]);
        material = getMaterial(data["material"]);

        object = Mesh(geometry, material);

        break;

      case 'InstancedMesh':
        geometry = getGeometry(data["geometry"]);
        material = getMaterial(data["material"]);
        final count = data["count"];
        final instanceMatrix = data["instanceMatrix"];
        final instanceColor = data["instanceColor"];

        object = InstancedMesh(geometry, material, count);
        object.instanceMatrix = InstancedBufferAttribute(Float32Array(instanceMatrix.array), 16, false);
        if (instanceColor != null) {
          object.instanceColor = InstancedBufferAttribute(Float32Array(instanceColor.array), instanceColor.itemSize, false);
        }

        break;

      // case 'LOD':

      // 	object = new LOD();

      // 	break;

      case 'Line':
        object =
            Line(getGeometry(data["geometry"]), getMaterial(data["material"]));

        break;

      case 'LineLoop':
        object = LineLoop(
            getGeometry(data["geometry"]), getMaterial(data["material"]));

        break;

      case 'LineSegments':
        object = LineSegments(
            getGeometry(data["geometry"]), getMaterial(data["material"]));

        break;

      case 'PointCloud':
      case 'Points':
        object = Points(
            getGeometry(data["geometry"]), getMaterial(data["material"]));

        break;

      case 'Sprite':
        object = Sprite(getMaterial(data["material"]));

        break;

      case 'Group':
        object = Group();

        break;

      case 'Bone':
        object = Bone();

        break;

      default:
        object = Object3D();
    }

    object.uuid = data["uuid"];

    if (data["name"] != null) object.name = data["name"];

    if (data["matrix"] != null) {
      object.matrix.fromArray(data["matrix"]);

      if (data["matrixAutoUpdate"] != null) {
        object.matrixAutoUpdate = data["matrixAutoUpdate"];
      }
      if (object.matrixAutoUpdate) {
        object.matrix
            .decompose(object.position, object.quaternion, object.scale);
      }
    } else {
      if (data["position"] != null) object.position.fromArray(data["position"]);
      if (data["rotation"] != null) object.rotation.fromArray(data["rotation"]);
      if (data["quaternion"] != null) {
        object.quaternion.fromArray(data["quaternion"]);
      }
      if (data["scale"] != null) object.scale.fromArray(data["scale"]);
    }

    if (data["castShadow"] != null) object.castShadow = data["castShadow"];
    if (data["receiveShadow"] != null) {
      object.receiveShadow = data["receiveShadow"];
    }

    if (data["shadow"] != null) {
      if (data["shadow"]["bias"] != null) {
        object.shadow.bias = data["shadow"]["bias"];
      }
      if (data["shadow"]["normalBias"] != null) {
        object.shadow.normalBias = data["shadow"]["normalBias"];
      }
      if (data["shadow"]["radius"] != null) {
        object.shadow.radius = data["shadow"]["radius"];
      }
      if (data["shadow"]["mapSize"] != null) {
        object.shadow.mapSize.fromArray(data["shadow"]["mapSize"]);
      }
      if (data["shadow"]["camera"] != null) {
        object.shadow.camera =
            parseObject(data["shadow"]["camera"], null, null, null, null);
      }
    }

    if (data["visible"] != null) object.visible = data["visible"];
    if (data["frustumCulled"] != null) {
      object.frustumCulled = data["frustumCulled"];
    }
    if (data["renderOrder"] != null) object.renderOrder = data["renderOrder"];
    if (data["userData"] != null) object.userData = data["userData"];
    if (data["layers"] != null) object.layers.mask = data["layers"];

    if (data["children"] != null) {
      final children = data["children"];

      for (int i = 0; i < children.length; i++) {
        object.add(parseObject(
            children[i], geometries, materials, textures, animations));
      }
    }

    if (data["animations"] != null) {
      final objectAnimations = data["animations"];

      for (int i = 0; i < objectAnimations.length; i++) {
        final uuid = objectAnimations[i];

        object.animations.push(animations[uuid]);
      }
    }

    if (data["type"] == 'LOD') {
      if (data["autoUpdate"] != null) object.autoUpdate = data["autoUpdate"];

      final levels = data["levels"];

      for (int l = 0; l < levels.length; l++) {
        final level = levels[l];
        final child = object.getObjectByProperty('uuid', level.object);

        if (child != null) {
          object.addLevel(child, level.distance);
        }
      }
    }

    return object;
  }

  bindSkeletons(object, skeletons) {
    if (skeletons.keys.length == 0) return;

    object.traverse((child) {
      if (child is SkinnedMesh && child.skeleton != null) {
        final skeleton = skeletons[child.skeleton];

        if (skeleton == null) {
          console.warning('ObjectLoader: No skeleton found with UUID: ${child.skeleton}');
        } else {
          child.bind(skeleton, child.bindMatrix);
        }
      }
    });
  }

  /* DEPRECATED */

  setTexturePath(value) {
    console.error('ObjectLoader: .setTexturePath() has been renamed to .setResourcePath().');
    return setResourcePath(value);
  }
}

final textureMapping = {
  "UVMapping": UVMapping,
  "CubeReflectionMapping": CubeReflectionMapping,
  "CubeRefractionMapping": CubeRefractionMapping,
  "EquirectangularReflectionMapping": EquirectangularReflectionMapping,
  "EquirectangularRefractionMapping": EquirectangularRefractionMapping,
  "CubeUVReflectionMapping": CubeUVReflectionMapping
};

final textureWrapping = {
  "RepeatWrapping": RepeatWrapping,
  "ClampToEdgeWrapping": ClampToEdgeWrapping,
  "MirroredRepeatWrapping": MirroredRepeatWrapping
};

final textureFilter = {
  "NearestFilter": NearestFilter,
  "NearestMipmapNearestFilter": NearestMipmapNearestFilter,
  "NearestMipmapLinearFilter": NearestMipmapLinearFilter,
  "LinearFilter": LinearFilter,
  "LinearMipmapNearestFilter": LinearMipmapNearestFilter,
  "LinearMipmapLinearFilter": LinearMipmapLinearFilter
};
