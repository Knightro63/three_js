import 'package:three_js_math/three_js_math.dart';
import './fog.dart';

class FogExp2 extends FogBase {
  FogExp2(Color color,[ double? density]) {
    name = 'FogExp2';
    this.color = color;
    this.density = (density != null) ? density : 0.00025;
    isFogExp2 = true;
  }

  FogExp2 clone() {
    return FogExp2(color, density);
  }

  @override
  Map<String,dynamic> toJson(/* meta */) {
    return {
      "type": 'FogExp2',
      "color": color.getHex(),
      "density": density
    };
  }
}
