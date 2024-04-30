import 'package:three_js_math/three_js_math.dart';
import '../core/curve.dart';
import '../core/interpolations.dart';

class QuadraticBezierCurve extends Curve {
  QuadraticBezierCurve(Vector2? v0, Vector2? v1, Vector2? v2) {

    this.v0 = v0 ?? Vector2();
    this.v1 = v1 ?? Vector2();
    this.v2 = v2 ?? Vector2();

    isQuadraticBezierCurve = true;
  }

  QuadraticBezierCurve.fromJson(Map<String, dynamic> json):super.fromJson(json) {
    v0.copyFromArray(json["v0"]);
    v1.copyFromArray(json["v1"]);
    v2.copyFromArray(json["v2"]);

    isQuadraticBezierCurve = true;
  }

  @override
  Vector? getPoint(double t, [Vector? optionalTarget]) {
    final point = optionalTarget ?? Vector2();

    final v0 = this.v0, v1 = this.v1, v2 = this.v2;

    point.setValues(PathInterpolations.quadraticBezier(t, v0.x, v1.x, v2.x),
        PathInterpolations.quadraticBezier(t, v0.y, v1.y, v2.y));

    return point;
  }

  @override
  QuadraticBezierCurve copy(Curve source) {
    if(source is QuadraticBezierCurve){
      super.copy(source);

      v0.setFrom(source.v0);
      v1.setFrom(source.v1);
      v2.setFrom(source.v2);
    }

    return this;
  }

  @override
  Map<String,dynamic> toJson() {
    Map<String,dynamic> data = super.toJson();

    data["v0"] = v0.copyIntoArray();
    data["v1"] = v1.copyIntoArray();
    data["v2"] = v2.copyIntoArray();

    return data;
  }
}
