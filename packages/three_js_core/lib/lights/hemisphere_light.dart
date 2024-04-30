import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light.dart';

class HemisphereLight extends Light {
  HemisphereLight(int? skyColor, int? groundColor, [double intensity = 1.0]):super(skyColor, intensity) {
    type = 'HemisphereLight';

    position.setFrom(Object3D.defaultUp);

    isHemisphereLight = true;
    updateMatrix();

    if (groundColor != null) {
      this.groundColor = Color.fromHex32(groundColor);
    }
  }

  @override
  HemisphereLight copy(Object3D source, [bool? recursive]) {
    super.copy(source);
    HemisphereLight source1 = source as HemisphereLight;
    groundColor!.setFrom(source1.groundColor!);
    return this;
  }
}
