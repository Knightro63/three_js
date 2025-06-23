import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_text/three_js_text.dart';

///
/// Requires opentype.js to be included in the project.
/// Loads TTF files and converts them into typeface JSON that can be used directly
/// to create THREE.Font objects.
///
class TTFLoader extends Loader {
  bool reversed = false;
  late final FileLoader _loader;

  TTFLoader([super.manager]){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }

  @override
  Future<TTFFont?> fromNetwork(Uri uri) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TTFFont> fromFile(File file) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TTFFont?> fromPath(String filePath) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TTFFont> fromBlob(Blob blob) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TTFFont?> fromAsset(String asset, {String? package}) async{
    throw("Not Available for WASM.");
  }
  @override
  Future<TTFFont> fromBytes(Uint8List bytes) async{
    throw("Not Available for WASM.");
  }
}
