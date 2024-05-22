import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'dart:math' as math;

final spotLightHelperVector = Vector3();

/// This displays a cone shaped helper object for a [SpotLight].
/// 
/// ```
/// final spotLight = SpotLight( 0xffffff );
/// spotLight.position.setValues( 10, 10, 10 );
/// scene.add( spotLight );
/// 
/// final spotLightHelper = SpotLightHelper( spotLight );
/// scene.add( spotLightHelper );
/// ```
class SpotLightHelper extends Object3D {
  late Light light;
  late int? color;
  late LineSegments cone;

  /// [light] -- The [SpotLight] to be visualized.
  ///
  /// [color] -- (optional) if this is not the set the helper will take
  /// the color of the light.
  SpotLightHelper(this.light, [this.color]) : super() {
    matrixAutoUpdate = false;
    light.updateMatrixWorld(false);

    matrix = light.matrixWorld;

    final geometry = BufferGeometry();

    List<double> positions = [
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      0,
      1,
      0,
      0,
      0,
      -1,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      1,
      0,
      0,
      0,
      0,
      -1,
      1
    ];

    for (int i = 0, j = 1, l = 32; i < l; i++, j++) {
      final p1 = (i / l) * math.pi * 2;
      final p2 = (j / l) * math.pi * 2;

      positions.addAll(
          [math.cos(p1), math.sin(p1), 1, math.cos(p2), math.sin(p2), 1]);
    }

    geometry.setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(positions), 3, false));

    final material = LineBasicMaterial.fromMap({"fog": false, "toneMapped": false});

    cone = LineSegments(geometry, material);
    add(cone);

    update();
  }

  @override
  void dispose() {
    cone.geometry?.dispose();
    cone.material?.dispose();
  }

  void update() {
    light.updateMatrixWorld(false);

    double coneLength = light.distance ?? 1000;
    final coneWidth = coneLength * math.tan(light.angle!);

    cone.scale.setValues(coneWidth, coneWidth, coneLength);

    spotLightHelperVector.setFromMatrixPosition(
        light.target!.matrixWorld);

    cone.lookAt(spotLightHelperVector);

    if (color != null) {
      cone.material!.color.setFromHex32(color!);
    } 
    else {
      cone.material!.color.setFrom(light.color!);
    }
  }
}
