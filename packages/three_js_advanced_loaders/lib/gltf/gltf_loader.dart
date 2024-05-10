import 'dart:async';
import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'gltf_extensions.dart';
import 'gltf_parser.dart';
import 'dart:io';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

class GLTFData{
  GLTFData({
    required this.scene,
    required this.scenes,
    this.animations,
    this.cameras,
    this.userData,
    this.asset,
    required this.parser
  });

  Object3D scene;
  List scenes;
  List? animations;
  List? cameras;
  dynamic asset;
  Map? userData;
  GLTFParser parser;
}

/// [glTF](https://www.khronos.org/gltf) (GL Transmission Format) is an
/// [open format specification](https://github.com/KhronosGroup/glTF/tree/master/specification/2.0)
/// for efficient delivery and loading of 3D content. Assets may be provided either in JSON (.gltf)
/// or binary (.glb) format. External files store textures (.jpg, .png) and additional binary
/// data (.bin). A glTF asset may deliver one or more scenes, including meshes, materials,
/// textures, skins, skeletons, morph targets, animations, lights, and/or cameras.
/// 
/// [GLTFLoader] uses [ImageBitmapLoader] whenever possible. Be advised that image bitmaps are not automatically GC-collected when they are no longer referenced,
/// and they require special handling during the disposal process. More information in the [How to dispose of objects](https://threejs.org/docs/#manual/en/introduction/How-to-dispose-of-objects) guide.
class GLTFLoader extends Loader {
  late final FileLoader _loader;
  late List<Function> pluginCallbacks;
  late dynamic _dracoLoader;
  late dynamic _ktx2Loader;
  late dynamic _ddsLoader;
  late dynamic _meshoptDecoder;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a new [FontLoader].
  GLTFLoader([super.manager]){
    _loader = FileLoader(manager);
    _dracoLoader = null;
    _ddsLoader = null;
    _ktx2Loader = null;
    _meshoptDecoder = null;

    pluginCallbacks = [];

    register((parser) {
      return GLTFMaterialsClearcoatExtension(parser);
    });

    register((parser) {
      return GLTFTextureBasisUExtension(parser);
    });

    register((parser) {
      return GLTFTextureWebPExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsSheenExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsTransmissionExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsVolumeExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsIorExtension(parser);
    });

    register((parser) {
      return GLTFMaterialsSpecularExtension(parser);
    });

    register((parser) {
      return GLTFLightsExtension(parser);
    });

    register((parser) {
      return GLTFMeshoptCompression(parser);
    });
  }
  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }

  void _init(){
    _loader.setPath(path);
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<GLTFData?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<GLTFData?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<GLTFData?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<GLTFData?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<GLTFData?> fromAsset(String asset, {String? package}) async{
    _init();
    if(path == ''){
      setPath(asset.replaceAll(asset.split('/').last, ''));
    }
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<GLTFData?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  @override
  GLTFLoader setPath(String path) {
    super.setPath(path);
    return this;
  }

  GLTFLoader setDRACOLoader(dracoLoader) {
    _dracoLoader = dracoLoader;
    return this;
  }

  GLTFLoader setDDSLoader(ddsLoader) {
    _ddsLoader = ddsLoader;
    return this;
  }

  GLTFLoader setKTX2Loader(ktx2Loader) {
    _ktx2Loader = ktx2Loader;
    return this;
  }

  GLTFLoader setMeshoptDecoder(meshoptDecoder) {
    _meshoptDecoder = meshoptDecoder;
    return this;
  }

  GLTFLoader register(Function callback) {
    if (pluginCallbacks.contains(callback)) {
      pluginCallbacks.add(callback);
    }

    return this;
  }

  GLTFLoader unregister(Function callback) {
    if (pluginCallbacks.contains(callback)) {
      pluginCallbacks.removeAt(pluginCallbacks.indexOf(callback));
    }

    return this;
  }

  Future<GLTFData> _parse(Uint8List data) {
    final String content;
    final extensions = {};
    final plugins = {};

    final magic = LoaderUtils.decodeText(Uint8List.view(data.buffer, 0, 4));
    if (magic == behm) {
      extensions[extensions["KHR_BINARY_GLTF"]] = GLTFBinaryExtension(data.buffer);
      content = extensions[extensions["KHR_BINARY_GLTF"]].content;
    } 
    else {
      content = LoaderUtils.decodeText(data);
    }
    

    Map<String, dynamic> json = convert.jsonDecode(content);

    if (json["asset"] == null || num.parse(json["asset"]["version"]) < 2.0) {
      throw('THREE.GLTFLoader: Unsupported asset. glTF versions >= 2.0 are supported.');
    }

    final parser = GLTFParser(json, {
      "path": path != ''?path:resourcePath ?? '',
      "crossOrigin": crossOrigin,
      "requestHeader": requestHeader,
      "manager": manager,
      "_ktx2Loader": _ktx2Loader,
      "_meshoptDecoder": _meshoptDecoder
    });

    parser.fileLoader.setRequestHeader(requestHeader);

    for (int i = 0; i < pluginCallbacks.length; i++) {
      final plugin = pluginCallbacks[i](parser);
      plugins[plugin.name] = plugin;

      // Workaround to avoid determining as unknown extension
      // in addUnknownExtensionsToUserData().
      // Remove this workaround if we move all the existing
      // extension handlers to plugin system
      extensions[plugin.name] = true;
    }

    if (json["extensionsUsed"] != null) {
      for (int i = 0; i < json["extensionsUsed"].length; ++i) {
        final extensionName = json["extensionsUsed"][i];
        final extensionsRequired = json["extensionsRequired"] ?? [];

        if (extensionName == extensions["KHR_MATERIALS_UNLIT"]) {
          extensions[extensionName] = GLTFMaterialsUnlitExtension();
        } else if (extensionName == extensions["KHR_MATERIALS_PBR_SPECULAR_GLOSSINESS"]) {
          extensions[extensionName] = GLTFMaterialsPbrSpecularGlossinessExtension();
        } else if (extensionName == extensions["KHR_DRACO_MESH_COMPRESSION"]) {
          extensions[extensionName] = GLTFDracoMeshCompressionExtension(json, _dracoLoader);
        } else if (extensionName == extensions["MSFT_TEXTURE_DDS"]) {
          extensions[extensionName] = GLTFTextureDDSExtension(_ddsLoader);
        } else if (extensionName == extensions["KHR_TEXTURE_TRANSFORM"]) {
          extensions[extensionName] = GLTFTextureTransformExtension();
        } else if (extensionName == extensions["KHR_MESH_QUANTIZATION"]) {
          extensions[extensionName] = GLTFMeshQuantizationExtension();
        } else {
          if (extensionsRequired.indexOf(extensionName) >= 0 && plugins[extensionName] == null) {
            console.warning('GLTFLoader: Unknown extension $extensionName.');
          }
        }
      }
    }

    parser.setExtensions(extensions);
    parser.setPlugins(plugins);
    return parser.parse();
  }
}
