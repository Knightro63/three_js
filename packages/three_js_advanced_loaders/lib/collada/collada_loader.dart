import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'collada_parser.dart';
import 'collada_data.dart';

class ColladaLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  ColladaLoader([super.manager]){
    _loader = FileLoader(manager);
    _init();
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
  Future<ColladaData?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<ColladaData?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<ColladaData?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<ColladaData?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<ColladaData?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset, package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<ColladaData?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  Future<ColladaData?> _parse(Uint8List bufferBytes) async{
    return parse(String.fromCharCodes(bufferBytes));
  }

	Future<ColladaData?> parse(String text) async{
    return ColladaParser(manager,text,path,crossOrigin).parse();
  }
}


