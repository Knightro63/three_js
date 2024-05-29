
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

/// An axis object to visualize the 3 axes in a simple way.
/// 
/// The X axis is red. The Y axis is green. The Z axis is blue.
/// 
/// ```
/// final axesHelper = AxesHelper( 5 );
/// scene.add( axesHelper );
/// ```
class AxesHelper extends LineSegments {
  AxesHelper.create({num size = 1, BufferGeometry? geometry, Material? material}):super(geometry, material){
    type = "AxesHelper";
  }
  
  /// [size] -- (optional) size of the lines representing the axes.
  /// Default is `1`.
  factory AxesHelper([num size = 1]) {
    List<double> vertices = [
      0,
      0,
      0,
      size.toDouble(),
      0,
      0,
      0,
      0,
      0,
      0,
      size.toDouble(),
      0,
      0,
      0,
      0,
      0,
      0,
      size.toDouble()
    ];

    List<double> colors = [
      1,
      0,
      0,
      1,
      0.6,
      0,
      0,
      1,
      0,
      0.6,
      1,
      0,
      0,
      0,
      1,
      0,
      0.6,
      1
    ];

    final geometry = BufferGeometry();
    geometry.setAttributeFromString('position',Float32BufferAttribute.fromList(vertices, 3, false));
    geometry.setAttributeFromString('color',Float32BufferAttribute.fromList(colors, 3, false));

    final material =
        LineBasicMaterial.fromMap({"vertexColors": true, "toneMapped": false});

    return AxesHelper.create(
        size: size, geometry: geometry, material: material);
  }

  /// Sets the axes colors to [xAxisColor], [yAxisColor],
  /// [zAxisColor].
  AxesHelper setColors(Color xAxisColor, Color yAxisColor, Color zAxisColor) {
    final color = Color(1, 1, 1);
    final array = geometry!.attributes["color"].array;

    color.setFrom(xAxisColor);
    color.copyIntoArray(array, 0);
    color.copyIntoArray(array, 3);

    color.setFrom(yAxisColor);
    color.copyIntoArray(array, 6);
    color.copyIntoArray(array, 9);

    color.setFrom(zAxisColor);
    color.copyIntoArray(array, 12);
    color.copyIntoArray(array, 15);

    geometry!.attributes["color"].needsUpdate = true;

    return this;
  }

  /// Frees the GPU-related resources allocated by this instance. Call this
  /// method whenever this instance is no longer used in your app.
  @override
  void dispose() {
    geometry!.dispose();
    material?.dispose();
  }
}
