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

class Fog extends FogBase {
  Fog(Color color, [double? near, double? far]) {
    name = 'Fog';
    this.color = color;
    this.near = near ?? 1;
    this.far = far ?? 1000;
    isFog = true;
  }

  Fog clone() {
    return Fog(color, near, far);
  }

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
