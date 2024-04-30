import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

class GridHelper extends LineSegments {

  GridHelper.create(super.geometry, super.material){
    type = 'GridHelper';
  }

  factory GridHelper([double size = 10, int divisions = 10, Color? color1, Color? color2]) {
    Color color_1 = color1 == null?Color.fromHex32(0x444444):Color.copy(color1);
    Color color_2 = color2 == null?Color.fromHex32(0x888888):Color.copy(color2);

    final center = divisions / 2;
    final step = size / divisions;
    final halfSize = size / 2;

    List<double> vertices = [];
    List<double> colors = List<double>.filled((divisions + 1) * 3 * 4, 0);
    double k = -halfSize;
    for (int i = 0, j = 0; i <= divisions; i++, k += step) {
      vertices.addAll([-halfSize, 0, k, halfSize, 0, k]);
      vertices.addAll([k, 0, -halfSize, k, 0, halfSize]);

      final color = (i == center) ? color_1 : color_2;

      color.copyIntoList(colors, j);
      j += 3;
      color.copyIntoList(colors, j);
      j += 3;
      color.copyIntoList(colors, j);
      j += 3;
      color.copyIntoList(colors, j);
      j += 3;
    }

    final geometry = BufferGeometry();
    geometry.setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(vertices), 3, false));
    geometry.setAttributeFromString('color',Float32BufferAttribute(Float32Array.from(colors), 3, false));

    final material = LineBasicMaterial.fromMap({"vertexColors": true, "toneMapped": false});

    return GridHelper.create(geometry, material);
  }
}
