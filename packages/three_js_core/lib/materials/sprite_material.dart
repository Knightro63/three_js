import './material.dart';
import 'package:three_js_math/three_js_math.dart';

class SpriteMaterial extends Material {
  SpriteMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  SpriteMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  SpriteMaterial.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson);

  void _init(){
    type = 'SpriteMaterial';
    transparent = true;
    color = Color(1, 1, 1);
    fog = true;
  }

  @override
  SpriteMaterial copy(Material source) {
    super.copy(source);
    color.setFrom(source.color);
    map = source.map;
    alphaMap = source.alphaMap;
    rotation = source.rotation;
    sizeAttenuation = source.sizeAttenuation;
    fog = source.fog;
    return this;
  }
}
