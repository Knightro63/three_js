import './material.dart';
import 'package:three_js_math/three_js_math.dart';

class PointsMaterial extends Material {
  PointsMaterial([Map<MaterialProperty, dynamic>? parameters]) {
    _init();
    setValues(parameters);
  }
  PointsMaterial.fromMap([Map<String, dynamic>? parameters]) {
    _init();
    setValuesFromString(parameters);
  }

  void _init(){
    type = "PointsMaterial";
    sizeAttenuation = true;
    color = Color(1, 1, 1);
    size = 1;

    fog = true;
  }

  @override
  PointsMaterial copy(Material source) {
    super.copy(source);
    color.setFrom(source.color);

    map = source.map;
    alphaMap = source.alphaMap;
    size = source.size;
    sizeAttenuation = source.sizeAttenuation;

    fog = source.fog;

    return this;
  }
}
