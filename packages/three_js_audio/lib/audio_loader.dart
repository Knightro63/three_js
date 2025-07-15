import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

SoLoud? soloud;

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
  Future<AudioSource?> fromNetwork(Uri uri) async{
    return await soloud?.loadUrl(uri.path);
  }
  @override
  Future<AudioSource?> fromFile(File file) async{
    return await soloud?.loadFile(file.path);
  }
  @override
  Future<AudioSource?> fromPath(String filePath) async{
    return await soloud?.loadFile(filePath);
  }
  @override
  Future<AudioSource?> fromAsset(String asset, {String? package}) async{
    asset = package != null?'packages/$package/${path+asset}':path+asset;
    return await soloud?.loadAsset(asset);
  }
  @override
  Future<Uint8List> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return tf.data;
  }

  @override
  Future<AudioSource?> unknown(dynamic url) async{
    if(url is File){
      return fromFile(url);
    }
    else if(url is Uri){
      return fromNetwork(url);
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
