import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

class AxesHelper extends LineSegments {
  AxesHelper.create({num size = 1, BufferGeometry? geometry, Material? material}):super(geometry, material){
    type = "AxesHelper";
  }
  
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
    geometry.setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(vertices), 3, false));
    geometry.setAttributeFromString('color',Float32BufferAttribute(Float32Array.from(colors), 3, false));

    final material =
        LineBasicMaterial.fromMap({"vertexColors": true, "toneMapped": false});

    return AxesHelper.create(
        size: size, geometry: geometry, material: material);
  }

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

  @override
  void dispose() {
    geometry!.dispose();
    material?.dispose();
  }
}
