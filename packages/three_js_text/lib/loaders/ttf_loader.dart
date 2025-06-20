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

  void _init(){
    _loader.setPath(path);
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<TTFFont?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<TTFFont> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<TTFFont?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<TTFFont> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<TTFFont?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<TTFFont> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  TTFFont _parse(Uint8List arraybuffer) {
    reverseCommands(commands) {
      final paths = [];
      List path = [];

      commands.forEach((c) {
        if (c.type.toLowerCase() == 'm') {
          path = [c];
          paths.add(path);
        } 
        else if (c.type.toLowerCase() != 'z') {
          path.add(c);
        }
      });

      final reversed = [];

      //paths.forEach((p) {
      for(int k = 0; k < paths.length;k++){
        final p = paths[k];
        final result = {
          "type": 'm',
          "x": p[p.length - 1].x,
          "y": p[p.length - 1].y
        };

        reversed.add(result);

        for (int i = p.length - 1; i > 0; i--) {
          final command = p[i];
          final result = {"type": command.type};

          if (command.x2 != null && command.y2 != null) {
            result["x1"] = command.x2;
            result["y1"] = command.y2;
            result["x2"] = command.x1;
            result["y2"] = command.y1;
          } else if (command.x1 != null && command.y1 != null) {
            result["x1"] = command.x1;
            result["y1"] = command.y1;
          }

          result["x"] = p[i - 1].x;
          result["y"] = p[i - 1].y;
          reversed.add(result);
        }
      }

      return reversed;
    }

    TTFFont convert(font, bool reversed) {

      final glyphs = {};
      final scale = (100000) / ((font.unitsPerEm ?? 2048) * 72);

      final glyphIndexMap = font.encoding.cmap["glyphIndexMap"];
      final unicodes = glyphIndexMap.keys.toList();

      for (int i = 0; i < unicodes.length; i++) {
        final unicode = unicodes[i];
        final glyph = font.glyphs.glyphs[glyphIndexMap[unicode]];

        if (unicode != null) {
          Map<String, dynamic> token = {
            "ha": (glyph.advanceWidth * scale).round(),
            "x_min": glyph.xMin != null ? (glyph.xMin * scale).round() : null,
            "x_max": glyph.xMax != null ? (glyph.xMax * scale).round() : null,
            "o": ''
          };

          if (reversed) {
            glyph.path.commands = reverseCommands(glyph.path.commands);
          }

          if (glyph.path != null) {
            glyph.path.commands.forEach((command) {
              if (command["type"].toLowerCase() == 'c') {
                command["type"] = 'b';
              }

              token["o"] += command["type"].toLowerCase() + ' ';

              if (command["x"] != null && command["y"] != null) {
                token["o"] += '${(command["x"] * scale).round()} ${ (command["y"] * scale).round()} ';
              }

              if (command["x1"] != null && command["y1"] != null) {
                token["o"] += '${(command["x1"] * scale).round()} ${(command["y1"] * scale).round()} ';
              }

              if (command["x2"] != null && command["y2"] != null) {
                token["o"] += '${(command["x2"] * scale).round()} ${(command["y2"] * scale).round()} ';
              }
            });
          }

          glyphs[String.fromCharCode(glyph.unicode)] = token;
        }
      }

      return TTFFont({
        "glyphs": glyphs,
        "familyName": font.getEnglishName('fullName'),
        "ascender": (font.ascender * scale).round(),
        "descender": (font.descender * scale).round(),
        "underlinePosition": font.tables["post"]["underlinePosition"],
        "underlineThickness": font.tables["post"]["underlineThickness"],
        "boundingBox": {
          "xMin": font.tables["head"]["xMin"],
          "xMax": font.tables["head"]["xMax"],
          "yMin": font.tables["head"]["yMin"],
          "yMax": font.tables["head"]["yMax"]
        },
        "resolution": 1000,
        "original_font_information": font.tables["name"]
      });
    }

    return convert(opentype.parseBuffer(arraybuffer, null), reversed); // eslint-disable-line no-undef
  }
}
