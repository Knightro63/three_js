import 'line_basic_material.dart';
import './material.dart';

/// A material for drawing wireframe-style geometries with dashed lines.
/// 
/// Note: You must call [computeLineDistances] when using [name].
/// 
/// ```
/// final material = LineDashedMaterial( {
///   MaterialProperty.color: 0xffffff,
///   MaterialProperty.linewidth: 1,
///   MaterialProperty.scale: 1,
///   MaterialProperty.dashSize: 3,
///   MaterialProperty.gapSize: 1,
/// });
/// ```
class LineDashedMaterial extends LineBasicMaterial {
  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [LineBasicMaterial])
  /// can be passed in here.
  LineDashedMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    type = 'LineDashedMaterial';
    scale = 1;
    dashSize = 3;
    gapSize = 1;
    setValues(parameters);
  }
  LineDashedMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    type = 'LineDashedMaterial';
    scale = 1;
    dashSize = 3;
    gapSize = 1;
    setValuesFromString(parameters);
  }
  @override
  LineDashedMaterial copy(Material source) {
    super.copy(source);
    scale = source.scale;
    dashSize = source.dashSize;
    gapSize = source.gapSize;
    return this;
  }
}
