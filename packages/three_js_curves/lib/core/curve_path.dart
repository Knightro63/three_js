import 'package:three_js_math/three_js_math.dart';
import 'curve.dart';
import '../curves/line_curve.dart';
import '../curves/line_curve3.dart';

/// ************************************************************
///	Curved Path - a curve path is simply a array of connected
///  curves, but retains the api of a curve
///*************************************************************/

class CurvePath extends Curve {
  CurvePath() : super() {
    curves = [];
    autoClose = false; // Automatically closes the path
  }

  CurvePath.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    autoClose = json["autoClose"];
    curves = [];

    for (int i = 0, l = json["curves"].length; i < l; i++) {
      final curve = json["curves"][i];
      curves.add(Curve.castJson(curve));
    }
  }

  void add(Curve curve) {
    curves.add(curve);
  }

  void closePath() {
    // Add a line curve if start and end of lines are not connected
    final startPoint = curves[0].getPoint(0);
    final endPoint = curves[curves.length - 1].getPoint(1);

    if (startPoint != null && endPoint != null && !startPoint.equals(endPoint)) {
      curves.add(LineCurve(endPoint, startPoint));
    }
  }

  // To get accurate point with reference to
  // entire path distance at time t,
  // following has to be done:

  // 1. Length of each sub path have to be known
  // 2. Locate and identify type of curve
  // 3. Get t for the curve
  // 4. Return curve.getPointAt(t')

  @override
  Vector? getPoint(double t, [Vector? optionalTarget]) {
    final d = t * getLength();
    final curveLengths = getCurveLengths();
    int i = 0;

    // To think about boundaries points.

    while (i < curveLengths.length) {
      if (curveLengths[i] >= d) {
        final diff = curveLengths[i] - d;
        final curve = curves[i];

        final segmentLength = curve.getLength();
        final double u = segmentLength == 0 ? 0 : 1 - diff / segmentLength;

        return curve.getPointAt(u, optionalTarget);
      }

      i++;
    }

    return null;

    // loop where sum != 0, sum > d , sum+1 <d
  }

  // We cannot use the default THREE.Curve getPoint() with getLength() because in
  // THREE.Curve, getLength() depends on getPoint() but in THREE.CurvePath
  // getPoint() depends on getLength

  @override
  double getLength() {
    final lens = getCurveLengths();
    return lens[lens.length - 1];
  }

  // cacheLengths must be recalculated.
  @override
  void updateArcLengths() {
    needsUpdate = true;
    cacheLengths = null;
    getCurveLengths();
  }

  // Compute lengths and cache them
  // We cannot overwrite getLengths() because UtoT mapping uses it.

  List<double> getCurveLengths() {
    // We use cache values if curves and cache array are same length

    if (cacheLengths != null && cacheLengths!.length == curves.length) {
      return cacheLengths!;
    }

    // Get length of sub-curve
    // Push sums into cached array

    List<double> lengths = [];
    double sums = 0.0;

    for (int i = 0, l = curves.length; i < l; i++) {
      sums += curves[i].getLength();
      lengths.add(sums);
    }

    cacheLengths = lengths;

    return lengths;
  }

  @override
  List<Vector?> getSpacedPoints([num divisions = 40, num offset = 0.0]) {
    final List<Vector?> points = [];

    for (int i = 0; i <= divisions; i++) {
      double offst = offset + i / divisions;
      if (offst > 1.0) {
        offst = offst - 1.0;
      }

      points.add(getPoint(offst));
    }

    if (autoClose) {
      points.add(points[0]);
    }

    return points;
  }

  @override
  List<Vector?> getPoints([int divisions = 12]) {
    final List<Vector?> points = [];
    Vector? last;
    final List<Curve> curves = this.curves;

    for (int i = 0; i < curves.length; i++) {
      final curve = curves[i];
      final resolution = (curve.isEllipseCurve)
          ? divisions * 2
          : ((curve is LineCurve || curve is LineCurve3))
              ? 1
              : (curve.isSplineCurve)
                  ? divisions * curve.points.length
                  : divisions;

      final pts = curve.getPoints(resolution);

      for (int j = 0; j < pts.length; j++) {
        final point = pts[j];

        if (last != null && last.equals(point!)) {
          continue;
        } // ensures no consecutive points are duplicates

        points.add(point);
        last = point;
      }
    }

    if (autoClose &&
        points.length > 1 &&
        points[points.length - 1] != null &&
        points[0] != null && 
        !points[points.length - 1]!.equals(points[0]!)) {
      points.add(points[0]);
    }

    return points;
  }

  @override
  CurvePath copy(Curve source) {
    assert(source is CurvePath);
    super.copy(source);

    curves = [];

    for (int i = 0, l = source.curves.length; i < l; i++) {
      final curve = source.curves[i];
      curves.add(curve.clone());
    }

    autoClose = source.autoClose;
    return this;
  }

  @override
  Map<String,dynamic> toJson() {
    Map<String,dynamic> data = super.toJson();

    data["autoClose"] = autoClose;
    data["curves"] = [];

    for (int i = 0, l = curves.length; i < l; i++) {
      final curve = curves[i];
      data["curves"].add(curve.toJson());
    }

    return data;
  }

  @override
  CurvePath fromJson(Map<String,dynamic> json) {
    super.fromJson(json);

    autoClose = json['autoClose'];
    // curves = [];

    // for (int i = 0, l = json['curves'].length; i < l; i++) {
    //   final curve = json['curves'][i];
    //   throw (" CurvePath fromJSON todo ");
    //   // curves.add(Curves[ curve.type ]().fromJSON( curve ) );
    // }

    return this;
  }
}
