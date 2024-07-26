import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

/// The Material Template Library format (MTL) or .MTL File Format is a companion file format to .OBJ that describes surface shading
/// (material) properties of objects within one or more .OBJ files.
class MTLLoader extends Loader {
  late final FileLoader _loader;
  dynamic materialOptions;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a new [MTLLoader].
  MTLLoader([super.manager]){
    _loader = FileLoader(manager);
  }
  void _init(){
    _loader.setPath(path);
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }
  @override
  Future<MaterialCreator?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<MaterialCreator> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<MaterialCreator?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<MaterialCreator> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<MaterialCreator?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset, package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<MaterialCreator> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  MTLLoader setMaterialOptions(value) {
    materialOptions = value;
    return this;
  }

  ///
	/// Parses a MTL file.
	///
	/// String text - Content of MTL file
	/// return MaterialCreator
	///
	/// see setPath setResourcePath
	///
	/// note In order for relative texture references to resolve correctly
	/// you must call setResourcePath() explicitly prior to parse.
	///
  MaterialCreator _parse(Uint8List bytes) {
    String text = String.fromCharCodes(bytes);
    List<String> lines = text.split('\n');
    Map<String,dynamic> info = {};
    final delimiterPattern = RegExp(r"\s+");
    final materialsInfo = {};

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      line = line.trim();

      if (line.isEmpty || line[0] == '#') {
        // Blank line or comment ignore
        continue;
      }

      final pos = line.indexOf(' ');

      String key = (pos >= 0) ? line.substring(0, pos) : line;
      key = key.toLowerCase();

      String value = (pos >= 0) ? line.substring(pos + 1) : '';
      value = value.trim();

      if (key == 'newmtl') {
        // New material

        info = {"name": value};
        materialsInfo[value] = info;
      } else {
        if (key == 'ka' || key == 'kd' || key == 'ks' || key == 'ke') {
          final ss = value.split(delimiterPattern);
          info[key] = [double.parse(ss[0]), double.parse(ss[1]), double.parse(ss[2])];
        } else {
          info[key] = value;
        }
      }
    }

    final materialCreator = MaterialCreator(resourcePath != "" ? resourcePath : path,materialOptions);
    materialCreator.setCrossOrigin(crossOrigin);
    materialCreator.setManager(manager);
    materialCreator.setMaterials(materialsInfo);
    return materialCreator;
  }
}

///
/// Create a MTLLoader.MaterialCreator
/// @param baseUrl - Url relative to which textures are loaded
/// @param options - Set of options on how to construct the materials
///                  side: Which side to apply the material
///                        FrontSide (default), THREE.BackSide, THREE.DoubleSide
///                  wrap: What type of wrapping to apply for textures
///                        RepeatWrapping (default), THREE.ClampToEdgeWrapping, THREE.MirroredRepeatWrapping
///                  normalizeRGB: RGBs need to be normalized to 0-1 from 0-255
///                                Default: false, assumed to be already normalized
///                  ignoreZeroRGBs: Ignore values of RGBs (Ka,Kd,Ks) that are all 0's
///                                  Default: false
/// @constructor
///

class MaterialCreator {
  late String baseUrl;
  late Map<String, dynamic>? options;
  late Map<String, dynamic> materialsInfo;
  late Map<String, dynamic> materials;
  late List materialsArray;
  late Map<String, dynamic> nameLookup;
  late String crossOrigin;
  late int side;
  late int wrap;

  dynamic manager;

  MaterialCreator(baseUrl, options) {
    this.baseUrl = baseUrl ?? "";
    this.options = options ?? {};
    materialsInfo = {};
    materials = {};
    materialsArray = [];
    nameLookup = {};

    crossOrigin = 'anonymous';

    side = (this.options?["side"] != null) ? this.options!["side"] : FrontSide;
    wrap = (this.options?["wrap"] != null) ? this.options!["wrap"] : RepeatWrapping;
  }

  MaterialCreator setCrossOrigin(value) {
    crossOrigin = value;
    return this;
  }

  void setManager(value) {
    manager = value;
  }

  void setMaterials(materialsInfo) {
    this.materialsInfo = convert(materialsInfo);
    materials = {};
    materialsArray = [];
    nameLookup = {};
  }

  Map<String, dynamic> convert(materialsInfo) {
    if (options == null) return materialsInfo;

    Map<String, dynamic> converted = {};

    for (final mn in materialsInfo.keys) {
      // Convert materials info into normalized form based on options

      final mat = materialsInfo[mn];

      Map<String, dynamic> covmat = {};

      converted[mn] = covmat;

      for (final prop in mat.keys) {
        bool save = true;
        dynamic value = mat[prop];
        final lprop = prop.toLowerCase();

        switch (lprop) {
          case 'kd':
          case 'ka':
          case 'ks':

            // Diffuse color (color under white light) using RGB values

            if (options != null && options!["normalizeRGB"] != null) {
              value = [value[0] / 255, value[1] / 255, value[2] / 255];
            }

            if (options != null && options!["ignoreZeroRGBs"] != null) {
              if (value[0] == 0 && value[1] == 0 && value[2] == 0) {
                // ignore

                save = false;
              }
            }

            break;

          default:
            break;
        }

        if (save) {
          covmat[lprop] = value;
        }
      }
    }

    return converted;
  }

  Future<void> preload() async {
    for (final mn in materialsInfo.keys) {
      await create(mn);
    }
  }

  getIndex(materialName) {
    return nameLookup[materialName];
  }

  getAsArray() async {
    int index = 0;

    for (final mn in materialsInfo.keys) {
      materialsArray[index] = await create(mn);
      nameLookup[mn] = index;
      index++;
    }

    return materialsArray;
  }

  create(String materialName) async {
    if (materials[materialName] == null) {
      await createMaterial_(materialName);
    }

    return materials[materialName];
  }

  createMaterial_(String materialName) async {
    // Create material

    final scope = this;
    final mat = materialsInfo[materialName];
    final Map<String,dynamic> params = {"name": materialName, "side": side};

    resolveURL(baseUrl, url) {
      if (url is! String || url == '') return '';

      // Absolute URL
      final reg = RegExp(r"^https?:\/\/", caseSensitive: false);
      if (reg.hasMatch(url)) return url;

      return baseUrl + url;
    }

    setMapForType(mapType, value) async {
      if (params[mapType] != null) return; // Keep the first encountered texture

      final texParams = scope.getTextureParams(value, params);

      final map = await scope.loadTexture(
          resolveURL(scope.baseUrl, texParams["url"]), null, null, null, null);

      map?.repeat.setFrom(texParams["scale"]);
      map?.offset.setFrom(texParams["offset"]);

      map?.wrapS = scope.wrap;
      map?.wrapT = scope.wrap;

      params[mapType] = map;
    }

    for (final prop in mat.keys) {
      final value = mat[prop];
      double n;

      if (value == '') continue;

      switch (prop.toLowerCase()) {

        // Ns is material specular exponent

        case 'kd':

          // Diffuse color (color under white light) using RGB values

          params["color"] = Color.fromList(value);

          break;

        case 'ks':

          // Specular color (color when light is reflected from shiny surface) using RGB values
          params["specular"] = Color.fromList(value);

          break;

        case 'ke':

          // Emissive using RGB values
          params["emissive"] = Color.fromList(value);

          break;

        case 'map_kd':

          // Diffuse texture map

          await setMapForType('map', value);

          break;

        case 'map_ks':

          // Specular map

          await setMapForType('specularMap', value);

          break;

        case 'map_ke':

          // Emissive map

          await setMapForType('emissiveMap', value);

          break;

        case 'norm':
          await setMapForType('normalMap', value);

          break;

        case 'map_bump':
        case 'bump':

          // Bump texture map

          await setMapForType('bumpMap', value);

          break;

        case 'map_d':

          // Alpha map

          await setMapForType('alphaMap', value);
          params["transparent"] = true;

          break;

        case 'ns':

          // The specular exponent (defines the focus of the specular highlight)
          // A high exponent results in a tight, concentrated highlight. Ns values normally range from 0 to 1000.

          params["shininess"] = double.parse(value);

          break;

        case 'd':
          n = double.parse(value);

          if (n < 1) {
            params["opacity"] = n;
            params["transparent"] = true;
          }

          break;

        case 'tr':
          n = double.parse(value);

          if (options != null && options?["invertTrProperty"]){
            n = 1 - n;
          }

          if (n > 0) {
            params["opacity"] = 1 - n;
            params["transparent"] = true;
          }

          break;

        default:
          break;
      }
    }

    materials[materialName] = MeshPhongMaterial.fromMap(params);
    return materials[materialName];
  }

  getTextureParams(String value, matParams) {
    Map<String, dynamic> texParams = {
      "scale": Vector2(1, 1),
      "offset": Vector2(0, 0)
    };

    final items = value.split(RegExp(r"\s+"));
    int pos;

    pos = items.indexOf('-bm');

    if (pos >= 0) {
      matParams.bumpScale = double.parse(items[pos + 1]);
      items.removeRange(pos, pos+2);
    }

    pos = items.indexOf('-s');

    if (pos >= 0) {
      texParams["scale"]!.setValues(double.parse(items[pos + 1]), double.parse(items[pos + 2]));
      items.removeRange(pos, pos+4);
    }

    pos = items.indexOf('-o');

    if (pos >= 0) {
      texParams["offset"]!.setValues(double.parse(items[pos + 1]), double.parse(items[pos + 2]));
      items.removeRange(pos, pos+4);
    }

    texParams["url"] = items.join(' ').trim();
    return texParams;
  }

  Future<Texture?> loadTexture(url, mapping, onLoad, onProgress, onError) async {
    final manager = (this.manager != null) ? this.manager : defaultLoadingManager;
     TextureLoader? loader = manager.getHandler(url);

    if (loader == null) {
      loader = TextureLoader(manager: manager);
      loader.flipY = true;
    }

    loader.setCrossOrigin(crossOrigin);

    // final texture = loader.load( url, onLoad, onProgress, onError );
    final texture = await loader.unknown(url);

    if (mapping != null) texture?.mapping = mapping;

    return texture;
  }
}
