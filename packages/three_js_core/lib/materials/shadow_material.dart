import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// This material can receive shadows, but otherwise is completely
/// transparent.
/// 
/// ```
/// final geometry = PlaneGeometry( 2000, 2000 );
/// geometry.rotateX(-math.pi/2);
///
/// final material = ShadowMaterial();
/// material.opacity = 0.2;
///
/// final plane = Mesh(geometry, material);
/// plane.position.y = -200;
/// plane.receiveShadow = true;
/// scene.add( plane );
/// ```
class ShadowMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material]) can be
  /// passed in here.
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
