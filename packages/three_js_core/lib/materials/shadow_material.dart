import './material.dart';
import 'package:three_js_math/three_js_math.dart';

class ShadowMaterial extends Material {
  ShadowMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  ShadowMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }

  void _init(){
    type = 'ShadowMaterial';
    color = Color.fromHex32(0x000000);
    transparent = true;
    fog = true;
  }
  @override
  ShadowMaterial copy(Material source) {
    super.copy(source);

    color.setFrom(source.color);
    fog = source.fog;
    return this;
  }

  @override
  ShadowMaterial clone() {
    return ShadowMaterial().copy(this);
  }
}
