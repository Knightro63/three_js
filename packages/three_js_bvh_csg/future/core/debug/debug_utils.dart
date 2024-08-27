import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math';
import 'dart:ui';

List<String> getTriangleDefinitions(List<Triangle> triangles) {
  String getVectorDefinition(Vector3 v) {
    return 'new Vector(${v.x},${v.y},${v.z})';
  }

  return triangles.map((t) {
    return ''' new Triangle(${getVectorDefinition(t.a)},${getVectorDefinition(t.b)},${getVectorDefinition(t.c)},)''';
  }).toList();
}

void logTriangleDefinitions(List<Triangle> triangles) {
  printToConsole(getTriangleDefinitions(triangles).join(',\n'));
}

void generateRandomTriangleColors(BufferGeometry geometry) {
  final position = geometry.attributes['position'];
  final array = Float32List(position.count * 3);

  final color = Color();
  for (int i = 0, l = array.length; i < l; i += 9) {
    color.setHSL(
      Random().nextDouble(), 
      lerpDouble(0.5, 1.0, Random().nextDouble())!,
      lerpDouble(0.5, 0.75, Random().nextDouble())!
    );

    array[i + 0] = color.red;
    array[i + 1] = color.green;
    array[i + 2] = color.blue;

    array[i + 3] = color.red;
    array[i + 4] = color.green;
    array[i + 5] = color.blue;

    array[i + 6] = color.red;
    array[i + 7] = color.green;
    array[i + 8] = color.blue;
  }
  
  geometry.setAttributeFromString('color', Float32BufferAttribute.fromList(array, 3));
}
