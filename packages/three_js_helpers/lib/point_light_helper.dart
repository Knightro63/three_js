import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

class PointLightHelper extends Mesh{
  late PointLight light;
  Color? color;

  PointLightHelper.create(super.geometry, super.material){
    type = "PointLightHelper";
  }

  factory PointLightHelper(light, sphereSize, Color color) {
    final geometry = SphereGeometry(sphereSize, 4, 2);
    final material = MeshBasicMaterial.fromMap({"wireframe": true, "fog": false, "toneMapped": false});

    final plh = PointLightHelper.create(geometry, material);

    plh.light = light;
    plh.light.updateMatrixWorld(false);

    plh.color = color;
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
