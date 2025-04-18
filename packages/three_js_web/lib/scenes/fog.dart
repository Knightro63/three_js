import 'package:three_js_math/three_js_math.dart';
import 'dart:js_interop';

class FogBase {
  String name = "";
  late Color color;

  late double density;
  late double near;
  late double far;

  bool isFog = false;
  bool isFogExp2 = false;

  FogBase clone() {
    throw(" need implement .... ");
  }

  Map<String,dynamic> toJson() {
    throw(" need implement .... ");
  }
}

@JS('Fog')
class Fog extends FogBase {
  external bool isFog;
  external double near;
  external double far;
  external Color color;

  /// The color parameter is passed to the [Color] constructor to set the color property.
  external Fog(int color, [double? near, double? far]);

  /// Returns a new fog instance with the same parameters as this one.
  @override
  external Fog clone();  
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
