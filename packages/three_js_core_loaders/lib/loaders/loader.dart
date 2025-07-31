import 'loading_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/blob.dart';

Map<String,dynamic> loading = {};

/// Base class for implementing loaders
abstract class Loader {
  late LoadingManager manager;
  late String crossOrigin;
  late bool withCredentials;
  late String path;
  String? resourcePath;
  late Map<String, dynamic> requestHeader;
  String responseType = "text";
  late String mimeType;
  bool flipY = false;

  /// [manager] — The [loadingManager]
  /// for the loader to use. Default is [DefaultLoadingManager].
  Loader([LoadingManager? manager, this.flipY = false]) {
    this.manager = (manager != null) ? manager : defaultLoadingManager;

    crossOrigin = 'anonymous';
    withCredentials = false;
    path = '';
    requestHeader = {};
  }

  /// [uri] - a uri containing the location of the file to be loaded 
  Future fromNetwork(Uri uri) async{
    throw (" load need implement ............. ");
  }

  /// [file] - the file to be loaded 
  Future fromFile(File file) async{
    throw (" load need implement ............. ");
  }

  /// [filePath] - path of the file to be loaded 
  Future fromPath(String filePath) async{
    throw (" load need implement ............. ");
  }

  /// [blob] - a blob of the file to be loaded
  Future fromBlob(Blob blob) async{
    throw (" load need implement ............. ");
  }

  /// [asset] - path of the file to be loaded 
  /// 
  /// [package] - if the file is from another flutter package add the name of the package here
  Future fromAsset(String asset, {String? package}) async{
    throw (" load need implement ............. ");
  }

  /// [bytes] - the loaded bytes of the file
  Future fromBytes(Uint8List bytes) async{
    throw (" load need implement ............. ");
  }

  /// [url] - a dynmaic data that gets parsed by the system
  Future unknown(url) async{
    throw (" load need implement ............. ");
  }

  //void parse(Map<String,dynamic> json, [String path = '', Function? onLoad, Function? onError]){}

  /// [crossOrigin] — The crossOrigin string to implement CORS for
  /// loading the url from a different domain that allows CORS.
  Loader setCrossOrigin(String crossOrigin) {
    this.crossOrigin = crossOrigin;
    return this;
  }

  /// Whether the XMLHttpRequest uses credentials such as cookies, authorization
  /// headers or TLS client certificates. See
  /// [XMLHttpRequest.withCredentials](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/withCredentials).
  /// 
  /// Note that this has no effect if you are loading files locally or from the
  /// same domain.
  Loader setWithCredentials(bool value) {
    withCredentials = value;
    return this;
  }

  /// [path] — Set the base path for the asset.
  Loader setPath(String path) {
    this.path = path;
    return this;
  }

  /// [resourcePath] — Set the base path for dependent resources
  /// like textures.
  Loader setResourcePath(String? resourcePath) {
    this.resourcePath = resourcePath;
    return this;
  }

  /// [requestHeader] - key: The name of the header whose value is
  /// to be set. value: The value to set as the body of the header.
  /// 
  /// Set the
  /// [request header](https://developer.mozilla.org/en-US/docs/Glossary/Request_header) used in HTTP request.
  Loader setRequestHeader(Map<String, dynamic> requestHeader) {
    this.requestHeader = requestHeader;
    return this;
  }

  void dispose(){
    loading.clear();
  }
}
