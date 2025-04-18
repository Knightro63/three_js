import './material.dart';
import 'dart:js_interop';

@JS('LineBasicMaterial')
class LineBasicMaterial extends Material {
  external LineBasicMaterial([Map? parameters]);

  LineBasicMaterial.fromMap([Map<String, dynamic>? parameters]){
    LineBasicMaterial(parameters);
  }
  
  /// Copy the parameters from the passed material into this material.
  @override
  external LineBasicMaterial copy(Material source);

  /// Return a new material with the same parameters as this material.
  @override
  external LineBasicMaterial clone();
}

