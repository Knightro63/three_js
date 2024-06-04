import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';
import '../curves/line_curve.dart';
import 'shape.dart';

/// Extensible curve object.
///
/// Some common of curve methods:
/// .getPoint( t, optionalTarget ), .getTangent( t, optionalTarget )
/// .getPointAt( u, optionalTarget ), .getTangentAt( u, optionalTarget )
/// .getPoints(), .getSpacedPoints()
/// .getLength()
/// .updateArcLengths()
///
/// This following curves inherit from THREE.Curve:
///
/// -- 2D curves --
/// THREE.ArcCurve
/// THREE.CubicBezierCurve
/// THREE.EllipseCurve
/// THREE.LineCurve
/// THREE.QuadraticBezierCurve
/// THREE.SplineCurve
///
/// -- 3D curves --
/// THREE.CatmullRomCurve3
/// THREE.CubicBezierCurve3
/// THREE.LineCurve3
/// THREE.QuadraticBezierCurve3
///
/// A series of curves can be represented as a THREE.CurvePath.
///
class Curve {
  
  /// This value determines the amount of divisions when calculating the
  /// cumulative segment lengths of a curve via [getLengths]. To ensure
  /// precision when using methods like [getSpacedPoints], it is
  /// recommended to increase [arcLengthDivisions] if the curve is very
  /// large. Default is `200`.
  late int arcLengthDivisions;

  bool needsUpdate = false;

  List<double>? cacheArcLengths;
  List<double>? cacheLengths;

  bool autoClose = false;
  List<Curve> curves = [];
  late List<Vector> points;

  bool isEllipseCurve = false;
  bool isLineCurve3 = false;
  bool isLineCurve = false;
  bool isSplineCurve = false;
  bool isCubicBezierCurve = false;
  bool isQuadraticBezierCurve = false;

  Vector2 currentPoint = Vector2();

  late Vector v0;
  late Vector v1;
  late Vector v2;

  Map<String, dynamic> userData = {};

  Curve() {
    arcLengthDivisions = 200;
  }

  Curve.fromJson(Map<String, dynamic> json) {
    arcLengthDivisions = json["arcLengthDivisions"];
    v1 = Vector2.fromJson(json["v1"]);
    v2 = Vector2.fromJson(json["v2"]);
  }

  static Curve castJson(Map<String, dynamic> json) {
    String type = json["type"];

    if (type == "Shape") {
      return Shape.fromJson(json);
    } else if (type == "Curve") {
      return Curve.fromJson(json);
    } else if (type == "LineCurve") {
      return LineCurve.fromJson(json);
    } else {
      throw " type: $type Curve.castJSON is not support yet... ";
    }
  }

  // Virtual base class method to overwrite and implement in subclasses
  //	- t [0 .. 1]
  @Deprecated('Curve: .getPoint() not implemented.')
  Vector? getPoint(double t, [Vector? optionalTarget]) {
    return null;
  }

  /// [u] - A position on the curve according to the arc length. Must
  /// be in the range [ 0, 1 ].
  /// 
  /// [optionalTarget] — (optional) If specified, the result will be
  /// copied into this Vector, otherwise a new Vector will be created.
  /// 
  /// 
  /// Returns a vector for a given position on the curve according to the arc
  /// length.
  Vector? getPointAt(double u, [Vector? optionalTarget]) {
    final t = getUtoTmapping(u);
    return getPoint(t, optionalTarget);
  }

  /// divisions -- number of pieces to divide the curve into. Default is `5`.
  /// 
  /// Returns a set of divisions + 1 points using getPoint( t ).
  List<Vector?> getPoints([int divisions = 5]) {
    final List<Vector?> points = [];

    for (int d = 0; d <= divisions; d++) {
      points.add(getPoint(d / divisions));
    }

    return points;
  }

  /// divisions -- number of pieces to divide the curve into. Default is `5`.
  /// 
  /// Returns a set of divisions + 1 equi-spaced points using getPointAt( u ).
  List<Vector?> getSpacedPoints([int divisions = 5, int offset = 0]) {
    final List<Vector?> points = [];

    for (int d = 0; d <= divisions; d++) {
      points.add(getPointAt(d / divisions));
    }

    return points;
  }

  /// Get total curve arc length
  double getLength() {
    final lengths = getLengths(null);
    return lengths[lengths.length - 1];
  }

  /// Get list of cumulative segment lengths
  List<double> getLengths(int? divisions) {
    divisions ??= arcLengthDivisions;

    if (cacheArcLengths != null &&
        (cacheArcLengths!.length == divisions + 1) &&
        !needsUpdate) {
      return cacheArcLengths!;
    }

    needsUpdate = false;

    List<double> cache = [];
    Vector? current;
    Vector last = getPoint(0)!;
    double sum = 0.0;

    cache.add(0);

    for (int p = 1; p <= divisions; p++) {
      current = getPoint(p / divisions);
      if(current != null){
        sum += current.distanceTo(last);
        cache.add(sum);
        last = current;
      }
    }

    cacheArcLengths = cache;

    return cache; // { sums: cache, sum: sum }; Sum is in the last element.
  }

  /// Update the cumulative segment distance cache. The method must be called
  /// every time curve parameters are changed. If an updated curve is part of a
  /// composed curve like [CurvePath], [updateArcLengths] must be
  /// called on the composed curve, too.
  void updateArcLengths() {
    needsUpdate = true;
    getLengths(null);
  }

  /// Given u in the range ( 0 .. 1 ), returns [t] also in the range
  /// ( 0 .. 1 ). u and t can then be used to give you points which are
  /// equidistant from the ends of the curve, using [getPoint].
  double getUtoTmapping(double u, [double? distance]) {
    final arcLengths = getLengths(null);

    int i = 0;
    int il = arcLengths.length;

    double targetArcLength; // The targeted u distance value to get

    if (distance != null) {
      targetArcLength = distance;
    } else {
      targetArcLength = u * arcLengths[il - 1];
    }

    // binary search for the index with largest value smaller than target u distance

    int low = 0, high = il - 1;
    double comparison;

    while (low <= high) {
      i = (low + (high - low) / 2).floor(); // less likely to overflow, though probably not issue here, JS doesn't really have integers, all doublebers are floats

      comparison = arcLengths[i] - targetArcLength;

      if (comparison < 0) {
        low = i + 1;
      } else if (comparison > 0) {
        high = i - 1;
      } else {
        high = i;
        break;

        // DONE

      }
    }

    i = high;

    if (arcLengths[i] == targetArcLength) {
      return i / (il - 1);
    }

    // we could get finer grain at lengths, or use simple interpolation between two points

    final lengthBefore = arcLengths[i];
    final lengthAfter = arcLengths[i + 1];

    final segmentLength = lengthAfter - lengthBefore;

    // determine where we are between the 'before' and 'after' points

    final segmentFraction = (targetArcLength - lengthBefore) / segmentLength;

    // add that fractional amount to t

    final t = (i + segmentFraction) / (il - 1);

    return t;
  }

  /// [t] - A position on the curve. Must be in the range [ 0, 1 ].
  /// 
  /// [optionalTarget] — (optional) If specified, the result will be
  /// copied into this Vector, otherwise a new Vector will be created.
  /// 
  /// 
  /// Returns a unit vector tangent at t. If the derived curve does not
  /// implement its tangent derivation, two points a small delta apart will be
  /// used to find its gradient which seems to give a reasonable approximation.
  Vector getTangent(double t, [Vector? optionalTarget]) {
    const delta = 0.0001;
    double t1 = t - delta;
    double t2 = t + delta;

    // Capping in case of danger

    if (t1 < 0) t1 = 0;
    if (t2 > 1) t2 = 1;

    final pt1 = getPoint(t1);
    final pt2 = getPoint(t2);

    final tangent = optionalTarget ??
      ((pt1.runtimeType == Vector2)?Vector2(): Vector3());

    if(pt2 != null && pt1 != null){
      tangent.setFrom(pt2).sub(pt1).normalize();
    }

    return tangent;
  }

  /// [u] - A position on the curve according to the arc length. Must
  /// be in the range [ 0, 1 ]. 
  /// 
  /// [optionalTarget] — (optional) If specified, the result will be
  /// copied into this Vector, otherwise a new Vector will be created.
  /// 
  /// 
  /// Returns tangent at a point which is equidistant to the ends of the curve
  /// from the point given in [getTangent].
  Vector getTangentAt(double u, [Vector? optionalTarget]) {
    final t = getUtoTmapping(u);
    return getTangent(t, optionalTarget);
  }

  /// Generates the Frenet Frames. Requires a curve definition in 3D space. Used
  /// in geometries like [TubeGeometry] or [ExtrudeGeometry].
  FrenetFrames computeFrenetFrames(int segments, bool closed) {
    // see http://www.cs.indiana.edu/pub/techreports/TR425.pdf

    final normal = Vector3();

    final List<Vector3> tangents = [];
    final List<Vector3> normals = [];
    final List<Vector3> binormals = [];

    final vec = Vector3();
    final mat = Matrix4();

    // compute the tangent vectors for each segment on the curve

    for (int i = 0; i <= segments; i++) {
      final u = i / segments;

      tangents.add(
        getTangentAt(u, Vector3()) as Vector3
      );
      tangents[i].normalize();
    }

    // select an initial normal vector perpendicular to the first tangent vector,
    // and in the direction of the minimum tangent xyz component

    normals.add(Vector3());
    binormals.add(Vector3());
    double min = double.maxFinite;
    final tx = tangents[0].x.abs();
    final ty = tangents[0].y.abs();
    final tz = tangents[0].z.abs();

    if (tx <= min) {
      min = tx;
      normal.setValues(1, 0, 0);
    }

    if (ty <= min) {
      min = ty;
      normal.setValues(0, 1, 0);
    }

    if (tz <= min) {
      normal.setValues(0, 0, 1);
    }

    vec.cross2(tangents[0], normal).normalize();

    normals[0].cross2(tangents[0], vec);
    binormals[0].cross2(tangents[0], normals[0]);

    // compute the slowly-varying normal and binormal vectors for each segment on the curve

    for (int i = 1; i <= segments; i++) {
      normals.add(normals[i - 1].clone());

      binormals.add(binormals[i - 1].clone());

      vec.cross2(tangents[i - 1], tangents[i]);

      if (vec.length > MathUtils.epsilon) {
        vec.normalize();

        final theta = math.acos(MathUtils.clamp(tangents[i - 1].dot(tangents[i]),
            -1, 1)); // clamp for floating pt errors

        normals[i].applyMatrix4(mat.makeRotationAxis(vec, theta));
      }

      binormals[i].cross2(tangents[i], normals[i]);
    }

    // if the curve is closed, postprocess the vectors so the first and last normal vectors are the same

    if (closed) {
      double theta = math.acos(MathUtils.clamp(normals[0].dot(normals[segments]), -1, 1));
      theta /= segments;

      if (tangents[0].dot(vec.cross2(normals[0], normals[segments])) >
          0) {
        theta = -theta;
      }

      for (int i = 1; i <= segments; i++) {
        // twist a little...
        normals[i].applyMatrix4(mat.makeRotationAxis(tangents[i], theta * i));
        binormals[i].cross2(tangents[i], normals[i]);
      }
    }

    return FrenetFrames(tangents: tangents, normals: normals, binormals: binormals);
  }

  /// Creates a clone of this instance.
  Curve clone() {
    return Curve().copy(this);
  }

  /// Copies another [name] object to this instance.
  Curve copy(Curve source) {
    arcLengthDivisions = source.arcLengthDivisions;
    return this;
  }

  /// Returns a JSON object representation of this instance.
  Map<String,dynamic> toJson() {
    Map<String, dynamic> data = {
      "metadata": {"version": 4.5, "type": 'Curve', "generator": 'Curve.toJson'}
    };

    data["arcLengthDivisions"] = arcLengthDivisions;
    data["type"] = runtimeType.toString();

    return data;
  }

  /// Copies the data from the given JSON object to this instance.
  Curve fromJson(Map<String,dynamic> json) {
    arcLengthDivisions = json['arcLengthDivisions'];

    return this;
  }
}

class FrenetFrames{
  FrenetFrames({
    this.tangents, 
    this.normals, 
    this.binormals
  });

  final List<Vector3>? tangents;
  final List<Vector3>? normals;
  final List<Vector3>? binormals;
}
