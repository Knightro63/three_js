import 'dart:async';
import 'dart:io';
import '../utils/blob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../loaders/loader.dart';
import '../utils/cache.dart';
import 'package:http/http.dart' as http;
import 'package:three_js_core/three_js_core.dart';
import 'image_loader_app.dart' if (dart.library.js_interop) 'image_loader_web.dart';

/// A loader for loading an [Image]. This is used internally by the
/// [CubeTextureLoader], [ObjectLoader] and [TextureLoader].
class ImageLoader extends Loader {
  /// [manager] — The [loadingManager]
  /// for the loader to use. Default is [DefaultLoadingManager].
  ImageLoader([super.manager, super.flipY = false]);

  @override
  Future<ImageElement?> fromNetwork(Uri uri) async{
    final url = uri.toString();
    final cacheName = url;
    
    final cached = Cache.get(cacheName);

    if (cached != null) {
      manager.itemStart(cacheName);
      manager.itemEnd(cacheName);
      return cached;
    }
    
    final http.Response? response = kIsWeb? null:await http.get(uri);
    final bytes = kIsWeb? null:response!.bodyBytes;
    final resp = await processImage(bytes,url,flipY);

    Cache.add(cacheName,resp);
    return resp;
  }
  @override
  Future<ImageElement?> fromFile(File file) async{
    final Uint8List data = await file.readAsBytes();
    return await fromBytes(data);
  }
  @override
  Future<ImageElement?> fromPath(String filePath) async{
    final File file = File(path+filePath);
    final Uint8List data = await file.readAsBytes();
    return await fromBytes(data);
  }
  @override
  Future<ImageElement?> fromBlob(Blob blob) async{
    if(kIsWeb){
      return await processImageBlob(blob,flipY);
    }
    return await fromBytes(blob.data);
  }
  @override
  Future<ImageElement?> fromAsset(String asset, {String? package}) async{
    asset = package != null?'packages/$package/${path+asset}':path+asset;
    final cacheName = asset;

    asset = manager.resolveURL(asset);
    final cached = Cache.get(cacheName);

    if (cached != null) {
      manager.itemStart(cacheName);
      manager.itemEnd(cacheName);
      return cached;
    }

    ImageElement? resp;
    if(!kIsWeb){
      final ByteData fileData = await rootBundle.load(asset);
      final bytes = fileData.buffer.asUint8List();
      resp = await processImage(bytes,asset,flipY);
    }
    else{
      resp = await processImage(null,asset,flipY);
    }
    
    Cache.add(cacheName,resp);
    return resp;
  }
  @override
  Future<ImageElement?> fromBytes(Uint8List bytes) async{
    String cacheName = String.fromCharCodes(bytes).toString().substring(0,50);
    final cached = Cache.get(cacheName);

    if (cached != null) {
      manager.itemStart(cacheName);
      manager.itemEnd(cacheName);
      return cached;
    }

    final resp = await processImage(bytes,null,flipY);
    Cache.add(cacheName,resp);
    return resp;
  }

  @override
  Future<ImageElement?> unknown(dynamic url) async{
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
      if(url.contains('http://') || url.contains('https://')){
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
}
