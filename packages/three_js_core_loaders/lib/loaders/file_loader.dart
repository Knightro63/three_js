import 'dart:async';
import 'dart:io';
import 'package:three_js_core/three_js_core.dart';

import '../utils/blob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'loader.dart';
import '../utils/cache.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class ThreeFile{
  ThreeFile(this.type,this.data,[this.location]);

  Uint8List data;
  String type;
  String? location;
}

/// A low level class for loading resources with Fetch, used internally by
/// most loaders. It can also be used directly to load any file type that does
/// not have a loader.
///
/// *Note:* The cache must be enabled using
/// `Cache.enabled = true;`
/// This is a global property and only needs to be set once to be used by all
/// loaders that use FileLoader internally. [Cache] is a cache
/// module that holds the response from each request made through this loader,
/// so each file is requested once.
class FileLoader extends Loader {
  FileLoader([super.manager]);

  @override
  Future<ThreeFile?> fromNetwork(Uri uri) async{
    final url = uri.path;
    final cacheName = url;
    
    final cached = Cache.get(cacheName);

    if (cached != null) {
      manager.itemStart(cacheName);
      manager.itemEnd(cacheName);
      return cached;
    }
    try{
      final http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        manager.itemError(url);
        manager.itemEnd(url);
      }

      final bytes = response.bodyBytes;

      Cache.add(cacheName,bytes);
      return ThreeFile('network',bytes,url);
    }
    catch(e){
      console.error('ThreeJS error: $e');
      return null;
    }
  }
  @override
  Future<ThreeFile> fromFile(File file) async{
    final Uint8List data = await file.readAsBytes();
    return await fromBytes(data,'file',file.path);
  }
  @override
  Future<ThreeFile?> fromPath(String filePath) async{
    try{
      final File file = File(path+filePath);
      final Uint8List data = await file.readAsBytes();
      return await fromBytes(data,'path',filePath);
    }catch(e){
      console.error('FileLoader error from path: ${path.substring(0,30)}');
      return null;
    }
  }
  @override
  Future<ThreeFile> fromBlob(Blob blob) async{
    if(kIsWeb){
      //final hblob = uhtml.Blob([blob.data.buffer], blob.options["type"]);
      return ThreeFile('blob',blob.data.buffer);
    }
    return await fromBytes(blob.data,'blob',blob.options["type"]);
  }
  @override
  Future<ThreeFile?> fromAsset(String asset, {String? package}) async{
    asset = package != null?'packages/$package/${path+asset}':path+asset;
    asset = manager.resolveURL(asset);
    final cacheName = asset;

    final cached = Cache.get(cacheName);

    if (cached != null) {
      manager.itemStart(cacheName);
      manager.itemEnd(cacheName);
      return ThreeFile('bytes',cached,'cache');
    }
    try{
      ByteData fileData = await rootBundle.load(asset);
      final bytes = fileData.buffer.asUint8List();
      Cache.add(cacheName,bytes);
      return ThreeFile('asset',bytes,asset);
    }
    catch(e){
      console.error('ThreeJS error: $e');
      return null;
    }
  }
  @override
  Future<ThreeFile> fromBytes(Uint8List bytes, [String? type, String? location]) async{
    String cacheName = String.fromCharCodes(bytes).toString().substring(0,50);
    final cached = Cache.get(cacheName);

    if (cached != null) {
      manager.itemStart(cacheName);
      manager.itemEnd(cacheName);
      return cached;
    }

    Cache.add(cacheName,bytes);
    return ThreeFile(type??'bytes',bytes,location);
  }

  Future<ThreeFile?> unknown(dynamic url) async{
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
      if(url.contains('http://') || url.contains('https://')){  
        return fromNetwork(Uri.parse(url));
      }
      else if(url.contains('assets')){
        return fromAsset(url);
      }
      else if(dataUriRegex.hasMatch(url)){
        RegExpMatch? dataUriRegexResult = dataUriRegex.firstMatch(url);
        String? data = dataUriRegexResult!.group(3)!;

        return ThreeFile('text', convert.base64.decode(data));
      }
      else{
        return fromPath(url);
      }
    }

    return null;
  }

  // bool _isDuplicate(String name){
  //   if (loading[name] != null) return true;
  //   return false;
  // }

  /// Change the response type. Valid values are:
  /// 
  /// [text] or empty string (default) - returns the data as
  /// [String].
  /// 
  /// [arraybuffer] - loads the data into a
  /// [ArrayBuffer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer) and returns that.
  /// 
  /// [blob] - returns the data as a
  /// [Blob](https://developer.mozilla.org/en/docs/Web/API/Blob).
  /// 
  /// [document] - parses the file using the
  /// [DOMParser](https://developer.mozilla.org/en-US/docs/Web/API/DOMParser).
  /// 
  /// [json] - parses the file using
  /// [JSON.parse](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse).
  /// 
  FileLoader setResponseType(String value) {
    responseType = value;
    return this;
  }

  /// Set the expected
  /// [mimeType](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types)
  /// of the file being loaded. Note that in many cases this will be
  /// determined automatically, so by default it is `null`.
  FileLoader setMimeType(String value) {
    mimeType = value;
    return this;
  }
}
