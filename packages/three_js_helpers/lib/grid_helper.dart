
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

/// The GridHelper is an object to define grids. Grids are two-dimensional
/// arrays of lines.
/// 
/// ```
/// const size = 10;
/// const divisions = 10;
///
/// final gridHelper = GridHelper( size, divisions );
/// scene.add( gridHelper );
/// ```
class GridHelper extends LineSegments {

  GridHelper.create(super.geometry, super.material){
    type = 'GridHelper';
  }

  /// [size] - The size of the grid. Default is `10`.
  /// 
  /// [divisions] - The number of divisions across the grid. Default is `10`.
  /// 
  /// [colorCenterLine] - The color of the centerline. This can be a
  /// [Color], a hexadecimal value and an CSS-Color name. Default is
  /// 0x444444 
  /// 
  /// [colorGrid] - The color of the lines of the grid. This can be a
  /// [Color], a hexadecimal value and an CSS-Color name. Default is
  /// 0x888888
  factory GridHelper([double size = 10, int divisions = 10, int? colorCenterLine, int? colorGrid]) {
    Color color_1 = Color.fromHex32(colorCenterLine??0x444444);
    Color color_2 = Color.fromHex32(colorGrid??0x888888);

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
    geometry.setAttributeFromString('position',Float32BufferAttribute.fromList(vertices, 3, false));
    geometry.setAttributeFromString('color',Float32BufferAttribute.fromList(colors, 3, false));

    final material = LineBasicMaterial.fromMap({"vertexColors": true, "toneMapped": false});

    return GridHelper.create(geometry, material);
  }
}
