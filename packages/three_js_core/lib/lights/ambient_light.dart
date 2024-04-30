import 'light.dart';

class AmbientLight extends Light {
  bool isAmbientLight = true;

  AmbientLight(super.color, [super.intensity]){
    type = 'AmbientLight';
  }

  AmbientLight.fromJson(Map<String,dynamic> json,Map<String,dynamic> rootJson):super.fromJson(json,rootJson){
    type = 'AmbientLight';
  }
}
