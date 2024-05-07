import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

final _v1 = Vector3();
final _v2 = Vector3();
final _v3 = Vector3();

/// Helper object to assist with visualizing a [page:DirectionalLight]'s
/// effect on the scene. This consists of plane and a line representing the
/// light's position and direction.
/// 
/// ```
/// final light = DirectionalLight( 0xFFFFFF );
/// scene.add( light );
///
/// final helper = DirectionalLightHelper( light, 5 );
/// scene.add( helper );
/// ```
class DirectionalLightHelper extends Object3D {
  late DirectionalLight light;
  late Line lightPlane;
  late Line targetLine;
  Color? color;

  /// [light]-- The light to be visualized.
  /// 
  /// [size] -- (optional) dimensions of the plane. Default is
  /// `1`.
  /// 
  /// [color] -- (optional) if this is not the set the helper will take
  /// the color of the light.
  DirectionalLightHelper(this.light, [double size = 1, this.color]) : super() {
    light.updateMatrixWorld(false);

    matrix = light.matrixWorld;
    matrixAutoUpdate = false;
    BufferGeometry geometry = BufferGeometry();

    List<double> posData = [
      -size,
      size,
      0.0,
      size,
      size,
      0.0,
      size,
      -size,
      0.0,
      -size,
      -size,
      0.0,
      -size,
      size,
      0.0
    ];

    geometry.setAttributeFromString('position', Float32BufferAttribute(Float32Array.from(posData), 3, false));

    final material = LineBasicMaterial.fromMap({"fog": false, "toneMapped": false});

    lightPlane = Line(geometry, material);
    add(lightPlane);

    geometry = BufferGeometry();
    List<double> d2 = [0, 0, 0, 0, 0, 1];
    geometry.setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(d2), 3, false));

    targetLine = Line(geometry, material);
    add(targetLine);

    update();
  }

  @override
  void dispose() {
    lightPlane.geometry!.dispose();
    lightPlane.material?.dispose();
    targetLine.geometry!.dispose();
    targetLine.material?.dispose();
  }

  void update() {
    _v1.setFromMatrixPosition(light.matrixWorld);
    _v2.setFromMatrixPosition(light.target!.matrixWorld);
    _v3.sub2(_v2, _v1);

    lightPlane.lookAt(_v2);

    if (color != null) {
      lightPlane.material?.color.setFrom(color!);
      targetLine.material?.color.setFrom(color!);
    } else {
      lightPlane.material?.color.setFrom(light.color!);
      targetLine.material?.color.setFrom(light.color!);
    }

    targetLine.lookAt(_v2);
    targetLine.scale.z = _v3.length;
  }
}
