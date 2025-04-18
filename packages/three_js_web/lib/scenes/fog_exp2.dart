import 'package:three_js_math/three_js_math.dart';
import './fog.dart';
import 'dart:js_interop';

@JS('FogExp2')
class FogExp2 extends FogBase {
  external Color color;
  external double density;

  external FogExp2(int color,[ double? density]);

  @override
  external FogExp2 clone();

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
