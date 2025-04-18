@JS('THREE')
import './light.dart';
import '../math/index.dart';
import 'dart:js_interop';

@JS('AmbientLight')
class AmbientLight extends Light {
  bool isAmbientLight = true;
  external AmbientLight([Color color, double intensity]);

  AmbientLight.fromJson(Map<String,dynamic> json,Map<String,dynamic> rootJson):super.fromJson(json,rootJson){
    type = 'AmbientLight';
  }
}
