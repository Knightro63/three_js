import 'loading_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/blob.dart';

Map<String,dynamic> loading = {};

abstract class Loader {
  late LoadingManager manager;
  late String crossOrigin;
  late bool withCredentials;
  late String path;
  String? resourcePath;
  late Map<String, dynamic> requestHeader;
  String responseType = "text";
  late String mimeType;
  //bool flipY = false;

  Loader([LoadingManager? manager]) {
    this.manager = (manager != null) ? manager : defaultLoadingManager;

    crossOrigin = 'anonymous';
    withCredentials = false;
    path = '';
    resourcePath = '';
    requestHeader = {};
  }

  Future fromNetwork(Uri uri) async{
    throw (" load need implement ............. ");
  }
  Future fromFile(File file) async{
    throw (" load need implement ............. ");
  }
  Future fromPath(String filePath) async{
    throw (" load need implement ............. ");
  }
  Future fromBlob(Blob blob) async{
    throw (" load need implement ............. ");
  }
  Future fromAsset(String asset, {String? package}) async{
    throw (" load need implement ............. ");
  }
  Future fromBytes(Uint8List bytes) async{
    throw (" load need implement ............. ");
  }

  //void parse(Map<String,dynamic> json, [String path = '', Function? onLoad, Function? onError]){}

  Loader setCrossOrigin(String crossOrigin) {
    this.crossOrigin = crossOrigin;
    return this;
  }

  Loader setWithCredentials(bool value) {
    withCredentials = value;
    return this;
  }

  Loader setPath(String path) {
    this.path = path;
    return this;
  }

  Loader setResourcePath(String? resourcePath) {
    this.resourcePath = resourcePath;
    return this;
  }

  Loader setRequestHeader(Map<String, dynamic> requestHeader) {
    this.requestHeader = requestHeader;
    return this;
  }


  void dispose(){
    loading.clear();
  }
}
