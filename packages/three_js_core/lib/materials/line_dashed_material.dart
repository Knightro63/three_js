import 'line_basic_material.dart';
import './material.dart';

class LineDashedMaterial extends LineBasicMaterial {
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
