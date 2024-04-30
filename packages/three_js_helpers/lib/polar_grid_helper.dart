import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'dart:math' as math;

class PolarGridHelper extends LineSegments {
  PolarGridHelper.create(geomertey, material) : super(geomertey, material);

  factory PolarGridHelper([
    radius = 10,
    radials = 16,
    circles = 8,
    divisions = 64,
    Color? color1,
    Color? color2
  ]) {
    Color clr1 = color1 == null?Color.fromHex32(0x444444):Color.copy(color1);
    Color clr2 = color2 == null?Color.fromHex32(0x888888):Color.copy(color2);

    List<double> vertices = [];
    List<double> colors = [];

    // create the radials

    for (int i = 0; i <= radials; i++) {
      final v = (i / radials) * (math.pi * 2);

      final x = math.sin(v) * radius;
      final z = math.cos(v) * radius;

      vertices.addAll([0, 0, 0]);
      vertices.addAll([x, 0, z]);

      final color = ((i & 1) != 0) ? clr1 : clr2;

      colors.addAll([color.red, color.green, color.blue]);
      colors.addAll([color.red, color.green, color.blue]);
    }

    // create the circles

    for (int i = 0; i <= circles; i++) {
      final color = ((i & 1) != 0) ? clr1 : clr2;
      final r = radius - (radius / circles * i);

      for (int j = 0; j < divisions; j++) {
        // first vertex

        double v = (j / divisions) * (math.pi * 2);

        double x = math.sin(v) * r;
        double z = math.cos(v) * r;

        vertices.addAll([x, 0, z]);
        colors.addAll([color.red, color.green, color.blue]);

        // second vertex

        v = ((j + 1) / divisions) * (math.pi * 2);

        x = math.sin(v) * r;
        z = math.cos(v) * r;

        vertices.addAll([x, 0, z]);
        colors.addAll([color.red, color.green, color.blue]);
      }
    }

    final geometry = BufferGeometry();
    geometry.setAttributeFromString('position', Float32BufferAttribute(Float32Array.from(vertices), 3));
    geometry.setAttributeFromString('color', Float32BufferAttribute(Float32Array.from(colors), 3));

    final material = LineBasicMaterial.fromMap({"vertexColors": true, "toneMapped": false});
    final pgh = PolarGridHelper.create(geometry, material);

    pgh.type = 'PolarGridHelper';
    return pgh;
  }
}
