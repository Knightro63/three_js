import 'package:three_js_math/three_js_math.dart';
import './fog.dart';

/// This class contains the parameters that define exponential squared fog,
/// which gives a clear view near the camera and a faster than exponentially
/// densening fog farther from the camera.
/// ```
/// final scene = Scene();
/// scene.fog = FogExp2(Color.fromHex32(0xcccccc), 0.002 );
/// ```
class FogExp2 extends FogBase {
  /// The color parameter is passed to the [Color] constructor to set the color property.
  FogExp2(int color,[ double? density]) {
    name = 'FogExp2';
    this.color = Color.fromHex32(color);
    this.density = density ?? 0.00025;
    isFogExp2 = true;
  }

  FogExp2.fromJson(Map<String,dynamic> json){
    name = 'FogExp2';
    this.color = Color.fromHex32(json['color'] ?? 0);
    this.density = json['density'] ?? 0.00025;
    isFogExp2 = true;
  }

  /// Returns a new FogExp2 instance with the same parameters as this one.
  @override
  FogExp2 clone() {
    return FogExp2(color.getHex(), density);
  }

  /// Return FogExp2 data in JSON format.
  @override
  Map<String,dynamic> toJson(/* meta */) {
    return {
      "type": 'FogExp2',
      "color": color.getHex(),
      "density": density
    };
  }
}
