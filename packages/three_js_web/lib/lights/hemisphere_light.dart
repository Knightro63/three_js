@JS('THREE')
import '../core/index.dart';
import 'light.dart';
import 'dart:js_interop';

@JS('HemisphereLight')
class HemisphereLight extends Light {
  external HemisphereLight(int? skyColor, int? groundColor, [double intensity = 1.0]);

  @override
  external HemisphereLight copy(Object3D source, [bool? recursive]);
}
