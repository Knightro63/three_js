
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'dart:math' as math;

/// The PolarGridHelper is an object to define polar grids. Grids are
/// two-dimensional arrays of lines.
/// 
/// ```
/// const radius = 10;
/// const sectors = 16;
/// const rings = 8;
/// const divisions = 64;
///
/// final helper = PolarGridHelper( radius, sectors, rings, divisions );
/// scene.add( helper );
/// ```
class PolarGridHelper extends LineSegments {
  PolarGridHelper.create(super.geomertey, super.material);

  /// [radius] - The radius of the polar grid. This can be any positive number.
  /// Default is `10`.
  /// 
  /// [sectors] - The number of sectors the grid will be divided into. This can
  /// be any positive integer. Default is `16`.
  /// 
  /// [rings] - The number of rings. This can be any positive integer. Default is
  /// 8.
  /// 
  /// [divisions] - The number of line segments used for each circle. This can be
  /// any positive integer that is 3 or greater. Default is `64`.
  /// 
  /// [color1] - The first color used for grid elements. This can be a
  /// [Color], a hexadecimal value and an CSS-Color name. Default is
  /// 0x444444
  /// 
  /// [color2] - The second color used for grid elements. This can be a
  /// [Color], a hexadecimal value and an CSS-Color name. Default is
  /// 0x888888
  factory PolarGridHelper([
    double radius = 10,
    int sectors = 16,
    int rings = 8,
    int divisions = 64,
    Color? color1,
    Color? color2
  ]) {
    Color clr1 = color1 == null?Color.fromHex32(0x444444):Color.copy(color1);
    Color clr2 = color2 == null?Color.fromHex32(0x888888):Color.copy(color2);

    List<double> vertices = [];
    List<double> colors = [];

    // create the radials

    for (int i = 0; i <= sectors; i++) {
      final v = (i / sectors) * (math.pi * 2);

      final x = math.sin(v) * radius;
      final z = math.cos(v) * radius;

      vertices.addAll([0, 0, 0]);
      vertices.addAll([x, 0, z]);

      final color = ((i & 1) != 0) ? clr1 : clr2;

      colors.addAll([color.red, color.green, color.blue]);
      colors.addAll([color.red, color.green, color.blue]);
    }

    // create the circles

    for (int i = 0; i <= rings; i++) {
      final color = ((i & 1) != 0) ? clr1 : clr2;
      final r = radius - (radius / rings * i);

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
    geometry.setAttributeFromString('position', Float32BufferAttribute.fromList(vertices, 3));
    geometry.setAttributeFromString('color', Float32BufferAttribute.fromList(colors, 3));

    final material = LineBasicMaterial.fromMap({"vertexColors": true, "toneMapped": false});
    final pgh = PolarGridHelper.create(geometry, material);

    pgh.type = 'PolarGridHelper';
    return pgh;
  }
}
