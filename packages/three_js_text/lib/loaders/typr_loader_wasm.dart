import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_text/three_js_text.dart';

/// Requires opentype.js to be included in the project.
/// Loads TTF files and converts them into typeface JSON that can be used directly
/// to create [Font] objects.
class TYPRLoader extends Loader {
  bool reversed = false;
  late final FileLoader _loader;

  TYPRLoader([super.manager]){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }

  @override
  Future<TYPRFont?> fromNetwork(Uri uri) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TYPRFont> fromFile(File file) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TYPRFont?> fromPath(String filePath) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TYPRFont> fromBlob(Blob blob) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TYPRFont?> fromAsset(String asset, {String? package}) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TYPRFont> fromBytes(Uint8List bytes) async{
    throw("Not Available for WASM.");
  }
}
