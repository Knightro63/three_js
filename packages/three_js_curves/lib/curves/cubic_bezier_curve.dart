import 'package:three_js_math/three_js_math.dart';
import '../core/curve.dart';
import '../core/interpolations.dart';

class CubicBezierCurve extends Curve {
  late Vector2 v3;

  CubicBezierCurve(Vector2? v0, Vector2? v1, Vector2? v2, Vector2? v3) {
    this.v0 = v0 ?? Vector2();
    this.v1 = v1 ?? Vector2();
    this.v2 = v2 ?? Vector2();
    this.v3 = v3 ?? Vector2();
    isCubicBezierCurve = true;
  }

  CubicBezierCurve.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    v0.copyFromArray(json["v0"]);
    v1.copyFromArray(json["v1"]);
    v2.copyFromArray(json["v2"]);
    v3.copyFromArray(json["v3"]);
    isCubicBezierCurve = true;
  }

  @override
  Vector? getPoint(double t, [Vector? optionalTarget]) {
    final point = optionalTarget ?? Vector2();

    final v0 = this.v0, v1 = this.v1, v2 = this.v2, v3 = this.v3;

    point.setValues(PathInterpolations.cubicBezier(t, v0.x, v1.x, v2.x, v3.x),PathInterpolations.cubicBezier(t, v0.y, v1.y, v2.y, v3.y));

    return point;
  }

  @override
  CubicBezierCurve copy(Curve source) {
    if(source is CubicBezierCurve){
      super.copy(source);

      v0.setFrom(source.v0);
      v1.setFrom(source.v1);
      v2.setFrom(source.v2);
      v3.setFrom(source.v3);
    }

    return this;
  }

  @override
  Map<String,dynamic> toJson() {
    Map<String,dynamic> data = super.toJson();

    data["v0"] = v0.copyIntoArray();
    data["v1"] = v1.copyIntoArray();
    data["v2"] = v2.copyIntoArray();
    data["v3"] = v3.copyIntoArray();

    return data;
  }
}
