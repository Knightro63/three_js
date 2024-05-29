import 'dart:async';
import 'dart:io';
import 'dart:convert' as convert;
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
class TextureLoader extends Loader {
  TextureLoader({LoadingManager? manager,this.flipY = false}):super(manager);
  bool flipY;

  Texture? _textureProcess(ImageElement? imageElement, String url){
    final Texture texture = Texture();

    //image = image?.convert(format:Format.uint8,numChannels: 4);
    if(imageElement != null){
      // ImageElement imageElement = ImageElement(
      //   url: url,
      //   data: Uint8List.from(image.getBytes()),
      //   width: image.width,
      //   height: image.height
      // );
      texture.image = imageElement;
      texture.needsUpdate = true;

      return texture;
    }

    return null;
  }
  
  @override
  Future<Texture?> fromNetwork(Uri uri) async{
    final url = uri.path;
    final ImageElement? image = await ImageLoader(manager,flipY).fromNetwork(uri);
    return _textureProcess(image,url);
  }
  @override
  Future<Texture?> fromFile(File file) async{
    Uint8List bytes = await file.readAsBytes();
    final String url = String.fromCharCodes(bytes).toString().substring(0,50);
    final ImageElement? image = await ImageLoader(manager,flipY).fromBytes(bytes);
    return _textureProcess(image,url);
  }
  @override
  Future<Texture?> fromPath(String filePath) async{
    final loader = ImageLoader(manager,flipY);
    loader.setPath(path);
    final ImageElement? image = await loader.fromPath(filePath);
    return _textureProcess(image,filePath);
  }
  @override
  Future<Texture?> fromBlob(Blob blob) async{
    final String url = String.fromCharCodes(blob.data).toString().substring(0,50);
    final ImageElement? image = await ImageLoader(manager,flipY).fromBlob(blob);
    return _textureProcess(image,url);
  }
  @override
  Future<Texture?> fromAsset(String asset, {String? package}) async{
    final loader = ImageLoader(manager,flipY);
    loader.setPath(path);
    final ImageElement? image = await loader.fromAsset(asset, package: package);
    return _textureProcess(image, package == null?asset:'$package/$asset');
  }
  @override
  Future<Texture?> fromBytes(Uint8List bytes) async{
    final String url = String.fromCharCodes(bytes).toString().substring(0,50);
    final ImageElement? image = await ImageLoader(manager,flipY).fromBytes(bytes);
    return _textureProcess(image,url);
  }

  /// If the type of format is unknown load it here.
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
      else if(url.contains('assets')){
        return fromAsset(url);
      }
      else{
        return fromPath(url);
      }
    }

    return null;
  }

  @override
  TextureLoader setPath(String path){
    super.setPath(path);
    return this;
  }
  @override
  TextureLoader setCrossOrigin(String crossOrigin) {
    super.setCrossOrigin(crossOrigin);
    return this;
  }
  @override
  TextureLoader setWithCredentials(bool value) {
    super.setWithCredentials(value);
    return this;
  }
  @override
  TextureLoader setResourcePath(String? resourcePath) {
    super.setResourcePath(resourcePath);
    return this;
  }
  @override
  TextureLoader setRequestHeader(Map<String, dynamic> requestHeader) {
    super.setRequestHeader(requestHeader);
    return this;
  }
}
