import 'package:three_js_math/three_js_math.dart';
import '../core/curve.dart';
import '../core/interpolations.dart';

class SplineCurve extends Curve {
  SplineCurve(List<Vector> points) : super() {
    this.points = points;
    isSplineCurve = true;
  }

  SplineCurve.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    points = [];

    for (int i = 0, l = json["points"].length; i < l; i++) {
      final point = json["points"][i];
      points.add(Vector2().copyFromArray(point));
    }

    isSplineCurve = true;
  }

  @override
  Vector? getPoint(double t, [Vector? optionalTarget]) {
    final point = optionalTarget ?? Vector2();

    final points = this.points;
    double p = (points.length - 1) * t;

    final intPoint = p.floor();
    final weight = p - intPoint;

    final p0 = points[intPoint == 0 ? intPoint : intPoint - 1];
    final p1 = points[intPoint];
    final p2 = points[intPoint > points.length - 2 ? points.length - 1 : intPoint + 1];
    final p3 = points[intPoint > points.length - 3 ? points.length - 1 : intPoint + 2];

    point.setValues(PathInterpolations.catmullRom(weight, p0.x, p1.x, p2.x, p3.x),PathInterpolations.catmullRom(weight, p0.y, p1.y, p2.y, p3.y));

    return point;
  }

  @override
  SplineCurve copy(Curve source) {
    if(source is SplineCurve){
      super.copy(source);

      points = [];

      for (int i = 0, l = source.points.length; i < l; i++) {
        final point = source.points[i];

        points.add(point.clone());
      }
    }

    return this;
  }

  @override
  Map<String,dynamic> toJson() {
    Map<String,dynamic> data = super.toJson();

    data["points"] = [];

    for (int i = 0, l = points.length; i < l; i++) {
      final point = points[i];
      data["points"].add(point.copyIntoArray());
    }

    return data;
  }
}
