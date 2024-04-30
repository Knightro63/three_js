import 'font.dart';
import 'package:three_js_curves/three_js_curves.dart';

class TTFFont extends Font {
  TTFFont(data) {
    this.data = data;
  }

  @override
  List<Shape> generateShapes(text, {double size = 100}) {
    List<Shape> shapes = [];
    final paths = createPaths(text, size, data);
    for (int p = 0, pl = paths.length; p < pl; p++) {
      // Array.prototype.push.apply( shapes, paths[ p ].toShapes() );
      shapes.addAll(paths[p].toShapes(false, false));
    }

    return shapes;
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
  Map<String, dynamic> createPath(char, double scale, double offsetX, double offsetY, data) {
    dynamic glyph = data["glyphs"][char] ?? data["glyphs"]['?'];

    if (glyph == null) {
      print(
          "THREE.Font: character $char does not exists in font family ${data.familyName}");
      // return null;
      glyph = data["glyphs"]["a"];
    }

    final path = ShapePath();

    double x = 0.1;
    double y = 0.1;
    double cpx, cpy, cpx1, cpy1, cpx2, cpy2;

    if (glyph["o"] != null) {
      dynamic outline = glyph["_cachedOutline"];

      if (outline == null) {
        glyph["_cachedOutline"] = glyph["o"].split(' ');
        outline = glyph["_cachedOutline"];
      }

      print(" outline scale: $scale ");
      print(outline);

      for (int i = 0, l = outline.length; i < l;) {
        final action = outline[i];
        i = i + 1;

        switch (action) {
          case 'm': // moveTo
            x = int.parse(outline[i++]) * scale + offsetX;
            y = int.parse(outline[i++]) * scale + offsetY;

            path.moveTo(x, y);
            break;

          case 'l': // lineTo

            x = int.parse(outline[i++]) * scale + offsetX;
            y = int.parse(outline[i++]) * scale + offsetY;

            path.lineTo(x, y);

            break;

          case 'q': // quadraticCurveTo

            cpx = int.parse(outline[i++]) * scale + offsetX;
            cpy = int.parse(outline[i++]) * scale + offsetY;
            cpx1 = int.parse(outline[i++]) * scale + offsetX;
            cpy1 = int.parse(outline[i++]) * scale + offsetY;

            path.quadraticCurveTo(cpx1, cpy1, cpx, cpy);

            break;

          case 'b': // bezierCurveTo

            cpx = int.parse(outline[i++]) * scale + offsetX;
            cpy = int.parse(outline[i++]) * scale + offsetY;
            cpx1 = int.parse(outline[i++]) * scale + offsetX;
            cpy1 = int.parse(outline[i++]) * scale + offsetY;
            cpx2 = int.parse(outline[i++]) * scale + offsetX;
            cpy2 = int.parse(outline[i++]) * scale + offsetY;

            path.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, cpx, cpy);

            break;
        }
      }
    }

    return {"offsetX": glyph["ha"] * scale, "path": path};
  }

  @override
  void dispose() {}
}
