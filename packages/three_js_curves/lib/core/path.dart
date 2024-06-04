import 'package:three_js_math/three_js_math.dart';
import 'curve.dart';
import 'curve_path.dart';
import '../curves/cubic_bezier_curve.dart';
import '../curves/ellipse_curve.dart';
import '../curves/line_curve.dart';
import '../curves/quadratic_bezier_curve.dart';
import '../curves/spline_curve.dart';

/// A 2D path representation. The class provides methods for creating paths
/// and contours of 2D shapes similar to the 2D Canvas API.
/// 
/// ```
/// final path = Path();
///
/// path.lineTo( 0, 0.8 );
/// path.quadraticCurveTo( 0, 1, 0.2, 1 );
/// path.lineTo( 1, 1 );
///
/// final points = path.getPoints();
///
/// final geometry = BufferGeometry().setFromPoints( points );
/// final material = LineBasicMaterial( { color: 0xffffff } );
///
/// final line = Line( geometry, material );
/// scene.add( line );
///```
class Path extends CurvePath {
  /// [points] -- (optional) array of [Vector2].
  /// 
  /// Creates a Path from the points. The first point defines the offset, then
  /// successive points are added to the [curves] array as
  /// [LineCurves].
  /// 
  /// If no points are specified, an empty path is created and the
  /// [currentPoint] is set to the origin.
  Path([List<Vector2>? points]) : super() {
    if (points != null) {
      setFromPoints(points);
    }
  }

  Path.fromJson(Map<String,dynamic> json) : super.fromJson(json) {
    currentPoint.copyFromArray(json["currentPoint"]);
  }

  /// [points] -- array of [Vector2].
  /// 
  /// Points are added to the [curves] array as
  /// [LineCurves].
  Path setFromPoints(List<Vector2> points) {
    moveTo(points[0].x, points[0].y);

    for (int i = 1, l = points.length; i < l; i++) {
      lineTo(points[i].x, points[i].y);
    }

    return this;
  }

  /// Move the [currentPoint] to x, y.
  Path moveTo(double x, double y) {
    currentPoint.setValues(x, y);
    return this;
  }

  /// Connects a [LineCurve] from [currentPoint] to x, y onto the path.
  Path lineTo(double x, double y) {
    final curve = LineCurve(currentPoint.clone(), Vector2(x, y));
    curves.add(curve);
    currentPoint.setValues(x, y);
    return this;
  }

  /// Creates a quadratic curve from [currentPoint] with cpX and cpY as
  /// control point and updates [currentPoint] to x and y.
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

  /// This creates a bezier curve from [currentPoint] with (cp1X, cp1Y)
  /// and (cp2X, cp2Y) as control points and updates [currentPoint] to x
  /// and y.
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

  /// [points] - An array of [Vector2]
  /// 
  /// Connects a new [SplineCurve] onto the path.
  Path splineThru(List<Vector2> pts) {
    final npts = [currentPoint.clone()];
    npts.addAll(pts);

    final curve = SplineCurve(npts);
    curves.add(curve);

    currentPoint.setFrom(pts[pts.length - 1]);

    return this;
  }

  /// [aX], [aY] -- The center of the arc offset from the last call.
  /// 
  /// [aRadius] -- The radius of the arc.
  /// 
  /// [aStartAngle] -- The start angle in radians.
  /// 
  /// [aEndAngle] -- The end angle in radians.
  /// 
  /// [aClockwise] -- Sweep the arc clockwise. Defaults to `false`.
  /// 
  /// Adds an [EllipseCurve] to the path, positioned relative
  /// to [page:.currentPoint].
  Path arc(double aX, double aY, double aRadius, double aStartAngle, double aEndAngle, [bool? aClockwise]) {
    final x0 = currentPoint.x;
    final y0 = currentPoint.y;

    absarc(aX + x0, aY + y0, aRadius, aStartAngle, aEndAngle, aClockwise);

    return this;
  }

  /// [aX], [aY] -- The absolute center of the arc.
  /// 
  /// [aRadius] -- The radius of the arc.
  /// 
  /// [aStartAngle] -- The start angle in radians.
  /// 
  /// [aEndAngle] -- The end angle in radians.
  /// 
  /// [aClockwise] -- Sweep the arc clockwise. Defaults to `false`.
  /// 
  /// Adds an absolutely positioned [EllipseCurve] to the
  /// path.
  Path absarc(double aX, double aY, double aRadius, double aStartAngle, double aEndAngle, [bool? aClockwise]) {
    absellipse(
        aX, aY, aRadius, aRadius, aStartAngle, aEndAngle, aClockwise);

    return this;
  }

  /// [aX], [aY] -- The center of the ellipse offset from the last call.
  /// 
  /// [xRadius] -- The radius of the ellipse in the x axis.
  /// 
  /// [yRadius] -- The radius of the ellipse in the y axis.
  /// 
  /// [aStartAngle] -- The start angle in radians.
  /// 
  /// [aEndAngle] -- The end angle in radians.
  /// 
  /// [aClockwise] -- Sweep the ellipse clockwise. Defaults to `false`.
  /// 
  /// [aRotation] -- The rotation angle of the ellipse in radians, counterclockwise
  /// from the positive X axis. Optional, defaults to `0`.
  /// 
  /// Adds an [EllipseCurve] to the path, positioned relative
  /// to [currentPoint].
  Path ellipse(double aX, double aY, double xRadius, double yRadius, double aStartAngle, double aEndAngle, [bool? aClockwise, double? aRotation]) {
    final x0 = currentPoint.x;
    final y0 = currentPoint.y;

    absellipse(aX + x0, aY + y0, xRadius, yRadius, aStartAngle, aEndAngle,
        aClockwise, aRotation);

    return this;
  }

  /// [aX], [aY] -- The absolute center of the ellipse.
  /// 
  /// [xRadius] -- The radius of the ellipse in the x axis.
  /// 
  /// [yRadius] -- The radius of the ellipse in the y axis.
  /// 
  /// [aStartAngle] -- The start angle in radians.
  /// 
  /// [aEndAngle] -- The end angle in radians.
  /// 
  /// [aClockwise] -- Sweep the ellipse clockwise. Defaults to false.
  /// 
  /// [aRotation] -- The rotation angle of the ellipse in radians, counterclockwise
  /// from the positive X axis. Optional, defaults to `0`.
  /// 
  /// Adds an absolutely positioned [EllipseCurve] to the
  /// path.
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
