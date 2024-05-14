import 'package:three_js_math/three_js_math.dart';

class FogBase {
  String name = "";
  late Color color;

  late double density;
  late double near;
  late double far;

  bool isFog = false;
  bool isFogExp2 = false;

  Map<String,dynamic> toJson() {
    throw(" need implement .... ");
  }
}

/// This class contains the parameters that define linear fog, i.e., that
/// grows linearly denser with the distance.
/// ```
/// final scene = Scene();
/// scene.fog = Fog(Color.fromHex32(0xcccccc), 10, 15 );
/// ```
class Fog extends FogBase {
  /// The color parameter is passed to the [Color] constructor to set the color property.
  Fog(int color, [double? near, double? far]) {
    name = 'Fog';
    this.color = Color.fromHex32(color);
    this.near = near ?? 1;
    this.far = far ?? 1000;
    isFog = true;
  }

  /// Returns a new fog instance with the same parameters as this one.
  Fog clone() {
    return Fog(color.getHex(), near, far);
  }
  
  /// Return fog data in JSON format.
  @override
  Map<String,dynamic> toJson(/* meta */) {
    return {
      "type": 'Fog',
      "color": color.getHex(),
      "near": near,
      "far": far
    };
  }
}
