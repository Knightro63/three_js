import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'dart:math' as math;

final _vectorHemisphereLightHelper = Vector3();
final _color1 = Color(0, 0, 0);
final _color2 = Color(0, 0, 0);

class HemisphereLightHelper extends Object3D {
  Color? color;
  late Light light;

  HemisphereLightHelper(this.light, size, this.color) : super() {
    light.updateMatrixWorld(false);

    matrix = light.matrixWorld;
    matrixAutoUpdate = false;

    final geometry = OctahedronGeometry(size);
    geometry.rotateY(math.pi * 0.5);

    material = MeshBasicMaterial.fromMap({"wireframe": true, "fog": false, "toneMapped": false});
    if (color == null) material?.vertexColors = true;

    final position = geometry.getAttributeFromString('position');
    final colors = Float32Array(position.count * 3);

    geometry.setAttributeFromString('color', Float32BufferAttribute(colors, 3, false));
    add(Mesh(geometry, material));
    update();
  }

  @override
  void dispose() {
    children[0].geometry!.dispose();
    children[0].material?.dispose();
  }

  void update() {
    final mesh = children[0];

    if (color != null) {
      material?.color.setFrom(color!);
    } else {
      final colors = mesh.geometry!.getAttributeFromString('color');

      _color1.setFrom(light.color!);
      _color2.setFrom(light.groundColor!);

      for (int i = 0, l = colors.count; i < l; i++) {
        final color = (i < (l / 2)) ? _color1 : _color2;

        colors.setXYZ(i, color.red, color.green, color.blue);
      }

      colors.needsUpdate = true;
    }

    mesh.lookAt(_vectorHemisphereLightHelper
        .setFromMatrixPosition(light.matrixWorld)
        .negate());
  }
}
