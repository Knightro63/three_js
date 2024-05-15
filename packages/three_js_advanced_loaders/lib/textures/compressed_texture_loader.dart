import 'dart:async';
import 'dart:io';
import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_core/three_js_core.dart';

/// Class for loading a [texture]. This uses the
/// [ImageLoader] internally for loading files.
/// 
/// ```
/// final texture = await TextureLoader().fromAsset('textures/land_ocean_ice_cloud_2048.jpg' ); 
/// // immediately use the texture for material creation 
///
/// final material = MeshBasicMaterial({ MaterialProperty.map:texture});
/// ```
class CompressedTextureLoader extends Loader {
  late final FileLoader _loader; 
  final texture = CompressedTexture();
  List images = [];
  int loaded = 0;

  CompressedTextureLoader([super.manager]){
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
  Future<CompressedTexture?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return _parse(tf?.data);
  }
  
  @override
  Future<CompressedTexture?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  
  @override
  Future<CompressedTexture?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return _parse(tf?.data);
  }
  
  @override
  Future<CompressedTexture?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  
  @override
  Future<CompressedTexture?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset, package: package);
    return _parse(tf?.data);
  }
  
  @override
  Future<CompressedTexture?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  /// If the type of format is unknown load it here.
  Future<CompressedTexture?> unknown(dynamic url) async{
    if(url is List){
			for (int i = 0, il = url.length; i < il; ++ i ) {
				loadTexture(i, url[i]);
			}

      return texture;
    }
    else if(url is File){
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
      else if(url.contains('assets')){
        return fromAsset(url);
      }
      else{
        return fromPath(url);
      }
    }

    return null;
  }

  Future<CompressedTexture?> _parse(Uint8List? buffer) async{
    if(buffer == null) return null;

    // compressed cubemap texture stored in a single DDS file
    final texDatas = parse( buffer.buffer, true );
    if ( texDatas['isCubemap'] ) {
      final faces = (texDatas['mipmaps'] as List).length / texDatas['mipmapCount'];
      for (int f = 0; f < faces; f ++ ) {
        images[f] = {'mipmaps': []};
        for (int i = 0; i < texDatas.mipmapCount; i ++ ) {
          (images[f]['mipmaps'] as List).add( texDatas['mipmaps'][ f * texDatas['mipmapCount'] + i ] );
          images[f]['format'] = texDatas['format'];
          images[f]['width'] = texDatas['width'];
          images[f]['height'] = texDatas['height'];
        }
      }

      texture.image = images;
    } else {
      texture.image['width'] = texDatas['width'];
      texture.image['height'] = texDatas['height'];
      texture.mipmaps = texDatas['mipmaps'];
    }

    if ( texDatas['mipmapCount'] == 1 ) {
      texture.minFilter = 1006;
    }

    texture.format = texDatas.format;
    texture.needsUpdate = true;

    return texture;
  }

  Future<Texture?> loadTexture(int i, Uint8List buffer) async{
    
    final texDatas = parse( buffer.buffer, true );

    images[i] = {
      'width': texDatas['width'],
      'height': texDatas['height'],
      'format': texDatas['format'],
      'mipmaps': texDatas['mipmaps']
    };

    loaded += 1;

    if ( loaded == 6 ) {
      if ( texDatas['mipmapCount'] == 1 ) texture.minFilter = 1006;
      texture.image = images;
      texture.format = texDatas['format'];
      texture.needsUpdate = true;
      return texture;
    }

    return null;
  }


  parse(ByteBuffer buffer, bool loadMipmaps){
    throw('not Implimented');
  }

  @override
  CompressedTextureLoader setPath(String path){
    super.setPath(path);
    return this;
  }
  @override
  CompressedTextureLoader setCrossOrigin(String crossOrigin) {
    super.setCrossOrigin(crossOrigin);
    return this;
  }
  @override
  CompressedTextureLoader setWithCredentials(bool value) {
    super.setWithCredentials(value);
    return this;
  }
  @override
  CompressedTextureLoader setResourcePath(String? resourcePath) {
    super.setResourcePath(resourcePath);
    return this;
  }
  @override
  CompressedTextureLoader setRequestHeader(Map<String, dynamic> requestHeader) {
    super.setRequestHeader(requestHeader);
    return this;
  }
}
