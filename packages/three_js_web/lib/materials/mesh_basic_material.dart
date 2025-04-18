import './material.dart';
import 'dart:js_interop';

@JS('MeshBasicMaterial')
class MeshBasicMaterial extends Material {
  external MeshBasicMaterial([Map? parameters]);
  MeshBasicMaterial.fromMap([Map<String, dynamic>? parameters]){
    MeshBasicMaterial(parameters);
  }

  /// Copy the parameters from the passed material into this material.
  @override
  external MeshBasicMaterial copy(Material source);

  /// Return a new material with the same parameters as this material.
  @override
  external MeshBasicMaterial clone();
}
