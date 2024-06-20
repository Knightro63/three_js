import 'light.dart';

/// This light globally illuminates all objects in the scene equally.
///
/// This light cannot be used to cast shadows as it does not have a direction.
/// 
/// ```
/// final light = AmbientLight(0x404040); // soft white light
/// scene.add( light );
/// ```
class AmbientLight extends Light {
  bool isAmbientLight = true;

  /// [color] - (optional) Color value of the RGB component of
  /// the color. Default is 0xffffff.
  /// 
  /// [intensity] - (optional) Numeric value of the light's
  /// strength/intensity. Default is `1`.
  /// 
  /// Creates a new [name].
  AmbientLight([super.color, super.intensity]){
    type = 'AmbientLight';
  }

  AmbientLight.fromJson(Map<String,dynamic> json,Map<String,dynamic> rootJson):super.fromJson(json,rootJson){
    type = 'AmbientLight';
  }
}
