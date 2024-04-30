import 'package:three_js_math/three_js_math.dart';
import 'curve.dart';
import 'curve_path.dart';
import '../curves/cubic_bezier_curve.dart';
import '../curves/ellipse_curve.dart';
import '../curves/line_curve.dart';
import '../curves/quadratic_bezier_curve.dart';
import '../curves/spline_curve.dart';

class Path extends CurvePath {
  Path([List<Vector2>? points]) : super() {
    if (points != null) {
      setFromPoints(points);
    }
  }

  Path.fromJson(Map<String,dynamic> json) : super.fromJson(json) {
    currentPoint.copyFromArray(json["currentPoint"]);
  }

  Path setFromPoints(List<Vector2> points) {
    moveTo(points[0].x, points[0].y);

    for (int i = 1, l = points.length; i < l; i++) {
      lineTo(points[i].x, points[i].y);
    }

    return this;
  }

  Path moveTo(double x, double y) {
    currentPoint.setValues(x, y);
    return this;
  }

  Path lineTo(double x, double y) {
    final curve = LineCurve(currentPoint.clone(), Vector2(x, y));
    curves.add(curve);
    currentPoint.setValues(x, y);
    return this;
  }

  Path quadraticCurveTo(double aCPx, double aCPy, double aX, double aY) {
    final curve = QuadraticBezierCurve(
      currentPoint.clone(),
      Vector2(aCPx, aCPy), 
      Vector2(aX, aY)
    );
    curves.add(curve);
    currentPoint.setValues(aX, aY);

    return this;
  }

  Path bezierCurveTo(double aCP1x, double aCP1y, double aCP2x, double aCP2y, double aX, double aY) {
    final curve = CubicBezierCurve(
      currentPoint.clone(),
      Vector2(aCP1x, aCP1y),
      Vector2(aCP2x, aCP2y),
      Vector2(aX, aY)
    );

    curves.add(curve);
    currentPoint.setValues(aX, aY);
    return this;
  }

  Path splineThru(List<Vector2> pts /*Array of Vector*/) {
    final npts = [currentPoint.clone()];
    npts.addAll(pts);

    final curve = SplineCurve(npts);
    curves.add(curve);

    currentPoint.setFrom(pts[pts.length - 1]);

    return this;
  }

  Path arc(double aX, double aY, double aRadius, double aStartAngle, double aEndAngle, [bool? aClockwise]) {
    final x0 = currentPoint.x;
    final y0 = currentPoint.y;

    absarc(aX + x0, aY + y0, aRadius, aStartAngle, aEndAngle, aClockwise);

    return this;
  }

  Path absarc(double aX, double aY, double aRadius, double aStartAngle, double aEndAngle, [bool? aClockwise]) {
    absellipse(
        aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);

    return this;
  }

  Path ellipse(double aX, double aY, double xRadius, double yRadius, double aStartAngle, double aEndAngle, [bool? aClockwise, double? aRotation]) {
    final x0 = currentPoint.x;
    final y0 = currentPoint.y;

    absellipse(aX + x0, aY + y0, xRadius, yRadius, aStartAngle, aEndAngle,
        aClockwise, aRotation);

    return this;
  }

  Path absellipse(double aX, double aY, double xRadius, double yRadius, double aStartAngle, double aEndAngle, [bool? aClockwise, double? aRotation]) {
    final curve = EllipseCurve(aX, aY, xRadius, yRadius, aStartAngle,
        aEndAngle, aClockwise, aRotation);

    if (curves.isNotEmpty) {
      // if a previous curve is present, attempt to join
      final firstPoint = curve.getPoint(0);

      if (firstPoint != null && !firstPoint.equals(currentPoint)) {
        lineTo(firstPoint.x, firstPoint.y);
      }
    }

    curves.add(curve);

    final lastPoint = curve.getPoint(1);
    if(lastPoint != null){
      currentPoint.setFrom(lastPoint);
    }

    return this;
  }

  @override
  Path copy(Curve source){
    assert(source is Path);
    super.copy(source);
    currentPoint.setFrom(source.currentPoint);
    return this;
  }

  @override
  Map<String,dynamic> toJson() {
    Map<String,dynamic> data = super.toJson();
    data["currentPoint"] = currentPoint.copyIntoArray();
    return data;
  }

  @override
  Path fromJson(Map<String,dynamic> json) {
    super.fromJson(json);

    currentPoint.copyFromArray(json['currentPoint']);
    return this;
  }
}
