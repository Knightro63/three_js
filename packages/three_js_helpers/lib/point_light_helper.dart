import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

/// This displays a helper object consisting of a spherical [Mesh] for
/// visualizing a [PointLight].
/// 
/// ```
/// final pointLight = PointLight( 0xff0000, 1, 100 );
/// pointLight.position.setValues( 10, 10, 10 );
/// scene.add( pointLight );
///
/// const sphereSize = 1.0;
/// final pointLightHelper = PointLightHelper( pointLight, sphereSize );
/// scene.add( pointLightHelper );
/// ```
class PointLightHelper extends Mesh{
  late PointLight light;
  Color? color;

  PointLightHelper.create(super.geometry, super.material){
    type = "PointLightHelper";
  }

  /// [light] -- The light to be visualized.
  /// 
  /// [sphereSize] -- (optional) The size of the sphere helper.
  /// Default is `1`.
  /// 
  /// [color] -- (optional) if this is not the set the helper will take
  /// the color of the light.
  factory PointLightHelper(PointLight light, double sphereSize, [int? color]) {
    final geometry = SphereGeometry(sphereSize, 4, 2);
    final material = MeshBasicMaterial.fromMap({"wireframe": true, "fog": false, "toneMapped": false});

    final plh = PointLightHelper.create(geometry, material);

    plh.light = light;
    plh.light.updateMatrixWorld(false);

    plh.color = color!=null?Color.fromHex32(color):null;
    plh.matrix = plh.light.matrixWorld;
    plh.matrixAutoUpdate = false;

    plh.update();
    return plh;
  }

  @override
  void dispose() {
    geometry?.dispose();
    material?.dispose();
  }

  void update() {
    if (color != null) {
      material?.color.setFrom(color!);
    } 
    else {
      material?.color.setFrom(light.color!);
    }
  }
}
