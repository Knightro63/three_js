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

  void _init(){
    _loader.setPath(path);
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<TYPRFont?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<TYPRFont> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<TYPRFont?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<TYPRFont> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<TYPRFont?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<TYPRFont> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  TYPRFont _parse(Uint8List arraybuffer) {
    TYPRFont convert(typr_dart.Font font, bool reversed) {
      return TYPRFont({
        "font": font,
        "familyName": font.getFamilyName(),
        "fullName": font.getFullName(),
        "underlinePosition": font.post["underlinePosition"],
        "underlineThickness": font.post["underlineThickness"],
        "boundingBox": {
          "xMin": font.head["xMin"],
          "xMax": font.head["xMax"],
          "yMin": font.head["yMin"],
          "yMax": font.head["yMax"]
        },
        "resolution": 1000,
        "original_font_information": font.name
      });
    }

    return convert(typr_dart.Font(arraybuffer), reversed); // eslint-disable-line no-undef
  }
}
