import 'line_basic_material.dart';
import './material.dart';
import 'dart:js_interop';

@JS('LineDashedMaterial')
class LineDashedMaterial extends LineBasicMaterial {
  external LineDashedMaterial([Map? parameters]);
  LineDashedMaterial.fromMap([Map<String, dynamic>? parameters]){
    LineDashedMaterial(parameters);
  }
  @override
  external LineDashedMaterial copy(Material source);
}
