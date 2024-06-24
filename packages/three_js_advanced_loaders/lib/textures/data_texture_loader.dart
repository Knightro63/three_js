import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert' as convert;
import 'package:three_js_core/textures/index.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

class TextureLoaderData{
  TextureLoaderData({
    this.width,
    this.height,
    this.data,
    required this.type,
    this.format,
    this.gamma,
    this.exposure,
    this.header,
    this.mipmapCount,
    this.generateMipmaps,
    this.flipY,
    this.encoding,
    this.anisotropy = 1,
    this.minFilter = LinearFilter,
    this.magFilter = LinearFilter,
    this.wrapS = ClampToEdgeWrapping,
    this.wrapT = ClampToEdgeWrapping,
    this.image
  });
  
  num? width;
  num? height;
  dynamic data;
  String? header;
  int? format;
  num? gamma;
  num? exposure;
  int type;
  int? mipmapCount;
  bool? generateMipmaps;
  List? mipmaps;
  bool? flipY;
  int? encoding;
  int anisotropy;
  int? minFilter;
  int? magFilter;
  int? wrapS;
  int? wrapT;
  dynamic image;

  DataTexture toDataTexture(){
    DataTexture dt = DataTexture.fromMap(json);
    dt.flipY = flipY ?? false;
    dt.generateMipmaps = generateMipmaps ?? false;

    return dt;
  }

  Map<String,dynamic> get json => {
    'width': width,
    'height': height,
    'data': data,
    'header': header,
    'format': format,
    'gamma': gamma,
    'exposure': exposure,
    'type': type,
    'mipmapCount': mipmapCount,
    'generateMipmaps': generateMipmaps,
    'mipmaps': mipmaps,
    'flipY': flipY,
    'encoding': encoding,
    'anisotropy': anisotropy,
    'magFilter': magFilter,
    'minFilter': minFilter,
    'wrapS': wrapS,
    'wrapT': wrapT
  };
}

/// Abstract Base class to load generic binary textures formats (rgbe, hdr, ...)
///
/// Sub classes have to implement the parse() method which will be used in load().
class DataTextureLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  DataTextureLoader([super.manager]){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }
  
  void _init(){
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setPath(path);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<DataTexture?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  
  @override
  Future<DataTexture?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  /// If the type of format is unknown load it here.
  @override
  Future<Texture?> unknown(dynamic url) async{
    if(url is File){
      return fromFile(url);
    }
    else if(url is Blob){
      return fromBlob(url);
    }
    else if(url is Uri){
      return fromNetwork(url);
    }
    else if(url is Uint8List){
      return fromBytes(url);
    }
    else if(url is String){
      RegExp dataUriRegex = RegExp(r"^data:(.*?)(;base64)?,(.*)$");
      if(dataUriRegex.hasMatch(url)){
        RegExpMatch? dataUriRegexResult = dataUriRegex.firstMatch(url);
        String? data = dataUriRegexResult!.group(3)!;

        return fromBytes(convert.base64.decode(data));
      }
      else if(url.contains('http://') || url.contains('https://')){  
        return fromNetwork(Uri.parse(url));
      }
      else if(url.contains('assets') || path.contains('assets')){
        return fromAsset(url);
      }
      else{
        return fromPath(url);
      }
    }

    return null;
  }

  DataTexture? _parse(Uint8List bytes){
    final Map<String,dynamic> texData = convert.json.decode(String.fromCharCodes(bytes));
    return parse(texData);
  }

  DataTexture? parse(Map<String,dynamic>? texData){
    if(texData == null) return null;
    final texture = DataTexture();


    if (texData['image'] != null) {
      texture.image = texData['image'];
    } 
    else if (texData["data"] != null) {
      texture.image.width = texData["width"].toInt();
      texture.image.height = texData["height"].toInt();
      texture.image.data = texData["data"];
    }

    texture.wrapS = texData["wrapS"] ?? ClampToEdgeWrapping;
    texture.wrapT = texData["wrapT"] ?? ClampToEdgeWrapping;

    texture.magFilter = texData["magFilter"] ?? LinearFilter;
    texture.minFilter = texData["minFilter"] ?? LinearFilter;

    texture.anisotropy = texData["anisotropy"] ?? 1;

    if (texData["encoding"] != null) {
      texture.encoding = texData["encoding"];
    }

    if (texData["flipY"] != null) {
      texture.flipY = texData["flipY"];
    }

    if (texData["format"] != null) {
      texture.format = texData["format"];
    }

    if (texData["type"] != null) {
      texture.type = texData["type"];
    }

    if (texData["mipmaps"] != null) {
      texture.mipmaps = texData["mipmaps"];
      texture.minFilter = LinearMipmapLinearFilter; // presumably...

    }

    if (texData["mipmapCount"] == 1) {
      texture.minFilter = LinearFilter;
    }

    if (texData["generateMipmaps"] != null) {
      texture.generateMipmaps = texData["generateMipmaps"];
    }

    texture.needsUpdate = true;

    return texture;
  }
}
