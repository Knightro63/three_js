@JS('THREE')
import 'light_shadow.dart';
import 'dart:js_interop';

@JS('DirectionalLightShadow')
class DirectionalLightShadow extends LightShadow {
  bool isDirectionalLightShadow = true;
  external DirectionalLightShadow();
}
