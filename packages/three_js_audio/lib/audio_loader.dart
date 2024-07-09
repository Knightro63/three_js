import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioLoader extends Loader {
  late final FileLoader _loader;

	AudioLoader([super.manager]){
		_loader = FileLoader(manager);
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
  Future<Uint8List?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf?.data;
  }
  @override
  Future<Uint8List> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return tf.data;
  }
  @override
  Future<Uint8List?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf?.data;
  }
  @override
  Future<Uint8List> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return tf.data;
  }
  @override
  Future<Uint8List?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf?.data;
  }
  @override
  Future<Uint8List> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return tf.data;
  }
}
