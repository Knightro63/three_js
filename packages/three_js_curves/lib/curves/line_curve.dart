import 'package:three_js_math/three_js_math.dart';
import '../core/curve.dart';

class LineCurve extends Curve {
  LineCurve(Vector v1, Vector v2) {
    if(v1 is! Vector2){
      v1 = Vector2(v1.x,v1.y);
    }
    if(v2 is! Vector2){
      v2 = Vector2(v2.x,v2.y);
    }
    this.v1 = v1;
    this.v2 = v2;
    isLineCurve = true;
  }

  LineCurve.fromJson(Map<String, dynamic> json):super.fromJson(json){
    isLineCurve = true;
  }

  @override
  Vector? getPoint(double t, [Vector? optionalTarget]) {
    final point = optionalTarget ?? Vector2();

    if (t == 1) {
      point.setFrom(v2);
    } else {
      point.setFrom(v2).sub(v1);
      point.scale(t).add(v1);
    }

    return point;
  }

  // Line curve is linear, so we can overwrite default getPointAt

  @override
  Vector? getPointAt(double u, [Vector? optionalTarget]) {
    return getPoint(u, optionalTarget);
  }

  @override
  Vector getTangent(double t, [Vector? optionalTarget]) {
    final tangent = optionalTarget ?? Vector2();
    tangent.setFrom(v2).sub(v1).normalize();
    return tangent;
  }

  @override
  LineCurve copy(source) {
    super.copy(source);

    v1.setFrom(source.v1);
    v2.setFrom(source.v2);

    return this;
  }

  @override
  Map<String,dynamic> toJson() {
    Map<String,dynamic> data = super.toJson();

    data["v1"] = v1.copyIntoArray();
    data["v2"] = v2.copyIntoArray();

    return data;
  }
}
