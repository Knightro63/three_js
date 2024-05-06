import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// A material for drawing wireframe-style geometries.
/// 
/// ```
/// final material = LineBasicMaterial({
///   MaterialProperty.color: 0xffffff,
///   MaterialProperty.linewidth: 1,
///   MaterialProperty.linecap: 'round', //ignored by WebGLRenderer
///   MaterialProperty.linejoin:  'round' //ignored by WebGLRenderer
/// });
/// ```
class LineBasicMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material]) can be
  /// passed in here.
  /// 
  /// The exception is the property [color], which can be
  /// passed in as a hexadecimal int and is 0xffffff (white) by default.
  /// [Color] is called internally.
  LineBasicMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    type = 'LineBasicMaterial';

    color = Color(1, 1, 1);
    linewidth = 1;
    linecap = 'round'; // 'butt', 'round' and 'square'.
    linejoin = 'round'; // 'round', 'bevel' and 'miter'.

    fog = true;

    setValues(parameters);
  }

  LineBasicMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    type = 'LineBasicMaterial';

    color = Color(1, 1, 1);
    linewidth = 1;
    linecap = 'round'; // 'butt', 'round' and 'square'.
    linejoin = 'round'; // 'round', 'bevel' and 'miter'.

    fog = true;

    setValuesFromString(parameters);
  }
  
  /// Copy the parameters from the passed material into this material.
  @override
  LineBasicMaterial copy(Material source) {
    super.copy(source);

    color.setFrom(source.color);

    linewidth = source.linewidth;
    linecap = source.linecap;
    linejoin = source.linejoin;

    fog = source.fog;

    return this;
  }

  /// Return a new material with the same parameters as this material.
  @override
  LineBasicMaterial clone() {
    return LineBasicMaterial({}).copy(this);
  }
}

