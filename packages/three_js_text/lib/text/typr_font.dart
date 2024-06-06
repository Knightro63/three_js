import 'font.dart';
import 'package:three_js_curves/three_js_curves.dart';

class TYPRFont extends Font {
  TYPRFont(data) {
    this.data = data;
  }

  @override
  List<Shape> generateShapes(text, {double size = 100}) {
    List<Shape> shapes = [];
    final paths = createPaths(text, size, data);

    for (int p = 0, pl = paths.length; p < pl; p++) {
      // Array.prototype.push.apply( shapes, paths[ p ].toShapes() );
      shapes.addAll(paths[p].toShapes(true, false));
    }

    return shapes;
  }

  Map<String, dynamic> generateShapes2(text, {double size = 100}) {
    return createPaths2(text, size, data);
  }

  Map<String, dynamic> createPaths2(
      String text, double size, Map<String, dynamic> data) {
    List<String> chars = text.split("");

    double scale = size / data["resolution"];
    double lineHeight = (data["boundingBox"]["yMax"] -
            data["boundingBox"]["yMin"] +
            data["underlineThickness"]) *
        scale;

    // List<ShapePath> paths = [];

    Map<String, Map<String, dynamic>> paths = {};
    List<Map<String, dynamic>> result = [];

    double offsetX = 0.0;
    double offsetY = 0.0;

    double maxWidth = 0.0;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      if (char == '\n') {
        offsetX = 0;
        offsetY -= lineHeight;
      } 
      else {
        Map<String, dynamic>? charPath = paths[char];
        if (charPath == null) {
          final ret = createPath(char, scale, 0.0, 0.0, data);
          paths[char] = ret;
          charPath = ret;
        }

        Map<String, dynamic> charData = {
          "char": char,
          "offsetX": offsetX,
          "offsetY": offsetY
        };

        result.add(charData);

        offsetX += charPath["offsetX"];
        // paths.add(ret["path"]);

        if (offsetX > maxWidth) {
          maxWidth = offsetX;
        }
      }
    }

    Map<String, dynamic> data2 = {
      "paths": paths,
      "chars": result,
      "height": offsetY + lineHeight,
      "width": maxWidth
    };

    return data2;
  }
  @override
  List<ShapePath> createPaths(
      String text, double size, Map<String, dynamic> data) {
    // final chars = Array.from ? Array.from( text ) : String( text ).split( '' ); // workaround for IE11, see #13988
    List<String> chars = text.split("");

    double scale = size / data["resolution"];
    double lineHeight = (data["boundingBox"]["yMax"] -
            data["boundingBox"]["yMin"] +
            data["underlineThickness"]) *
        scale;

    List<ShapePath> paths = [];

    double offsetX = 0.0;
    double offsetY = 0.0;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      if (char == '\n') {
        offsetX = 0;
        offsetY -= lineHeight;
      } 
      else {
        final ret = createPath(char, scale, offsetX, offsetY, data);
        offsetX += ret["offsetX"];
        paths.add(ret["path"]);
      }
    }

    return paths;
  }
  @override
  Map<String, dynamic> createPath(
      String char, double scale, double offsetX, double offsetY, data) {
    final font = data["font"];
    List<int> glyphs = List<int>.from(font.stringToGlyphs(char));

    final gid = glyphs[0];
    final charPath = font.glyphToPath(gid);

    final preScale = (100000) / ((font.head["unitsPerEm"] ?? 2048) * 72);
    // final _preScale = 1;
    final ha = (font.hmtx["aWidth"][gid] * preScale).round();

    final path = ShapePath();

    double x = 0.1;
    double y = 0.1;
    double cpx, cpy, cpx1, cpy1, cpx2, cpy2;

    final cmds = charPath["cmds"];
    List<double> crds = List<double>.from(charPath["crds"].map((e) => e.toDouble()));
    crds = crds.map((n) => (n * preScale).roundToDouble()).toList();

    int i = 0;
    int l = cmds.length;
    for (int j = 0; j < l; j++) {
      final action = cmds[j];

      switch (action) {
        case 'M': // moveTo
          x = crds[i++] * scale + offsetX;
          y = crds[i++] * scale + offsetY;

          path.moveTo(x, y);
          break;

        case 'L': // lineTo

          x = crds[i++] * scale + offsetX;
          y = crds[i++] * scale + offsetY;

          path.lineTo(x, y);

          break;

        case 'Q': // quadraticCurveTo

          cpx = crds[i++] * scale + offsetX;
          cpy = crds[i++] * scale + offsetY;
          cpx1 = crds[i++] * scale + offsetX;
          cpy1 = crds[i++] * scale + offsetY;

          path.quadraticCurveTo(cpx1, cpy1, cpx, cpy);

          break;

        case 'B':
        case 'C': // bezierCurveTo

          cpx = crds[i++] * scale + offsetX;
          cpy = crds[i++] * scale + offsetY;
          cpx1 = crds[i++] * scale + offsetX;
          cpy1 = crds[i++] * scale + offsetY;
          cpx2 = crds[i++] * scale + offsetX;
          cpy2 = crds[i++] * scale + offsetY;

          path.bezierCurveTo(cpx, cpy, cpx1, cpy1, cpx2, cpy2);

          break;
      }
    }

    return {"offsetX": ha * scale, "path": path};
  }
  @override
  void dispose() {}
}
