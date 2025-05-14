@JS('THREE')
import '../core/index.dart';
import 'light.dart';
import 'dart:js_interop';

@JS('DirectionalLight')
class DirectionalLight extends Light {
  bool isDirectionalLight = true;

  external DirectionalLight([color, double intensity]);

  @override
  external DirectionalLight copy(Object3D source, [bool? recursive]);

  @override
  external void dispose();
}
