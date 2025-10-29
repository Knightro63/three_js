import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';
import '../core/curve.dart';


class CubicPoly {
  num c0 = 0, c1 = 0, c2 = 0, c3 = 0;

  CubicPoly();
  
  void init(num x0, num x1, num t0, num t1) {
    c0 = x0;
    c1 = t0;
    c2 = -3 * x0 + 3 * x1 - 2 * t0 - t1;
    c3 = 2 * x0 - 2 * x1 + t0 + t1;
  }

  void initCatmullRom(num x0, num x1, num x2, num x3, num tension) {
    init(x1, x2, tension * (x2 - x0), tension * (x3 - x1));
  }

  void initNonuniformCatmullRom(num x0, num x1, num x2, num x3, num dt0, num dt1, num dt2) {
    // compute tangents when parameterized in [t1,t2]
    num t1 = (x1 - x0) / dt0 - (x2 - x0) / (dt0 + dt1) + (x2 - x1) / dt1;
    num t2 = (x2 - x1) / dt1 - (x3 - x1) / (dt1 + dt2) + (x3 - x2) / dt2;

    // rescale tangents for parametrization in [0,1]
    t1 *= dt1;
    t2 *= dt1;

    init(x1, x2, t1, t2);
  }

  double calc(double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    return c0 + c1 * t + c2 * t2 + c3 * t3;
  }
}

final tmp = Vector3();
final px = CubicPoly(), py = CubicPoly(), pz = CubicPoly();

/// Create a smooth 3d spline curve from a series of points using the
/// [Catmull-Rom](https://en.wikipedia.org/wiki/Centripetal_Catmull-Rom_spline)  algorithm.
/// ```
/// //Create a closed wavey loop
/// final curve = CatmullRomCurve3( [
///   Vector3( -10, 0, 10 ),
///   Vector3( -5, 5, 5 ),
///   Vector3( 0, 0, 0 ),
///   Vector3( 5, -5, 5 ),
///   Vector3( 10, 0, 10 )
/// ] );
///
/// final points = curve.getPoints( 50 );
/// final geometry = BufferGeometry().setFromPoints( points );
///
/// final material = LineBasicMaterial( { color: 0xff0000 } );
///
/// // Create the final object to add to the scene
// final curveObject = Line( geometry, material );
///```
class CatmullRomCurve3 extends Curve {
  bool isCatmullRomCurve3 = true;

  late bool closed;
  late String curveType;
  late num tension;

  /// [points] – An array of [Vector3] points
  /// 
  /// [closed] – Whether the curve is closed. Default is `false`.
  /// 
  /// [curveType] – Type of the curve. Default is `centripetal`.
  /// 
  /// [tension] – Tension of the curve. Default is `0.5`.
  CatmullRomCurve3({List<Vector>? points, this.closed = false, this.curveType = 'centripetal', this.tension = 0.5}): super() {
    this.points = points ?? [];
  }

  @override
  Vector3? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    if(optionalTarget is! Vector3){
      if(optionalTarget is Vector4){
        optionalTarget = Vector3(optionalTarget.x, optionalTarget.y, optionalTarget.z);
      }
      else{
        optionalTarget = Vector3(optionalTarget.x, optionalTarget.y);
      }
    }
    final point = optionalTarget;

    final points = this.points;
    final l = points.length;

    final p = (l - (closed ? 0 : 1)) * t;
    int intPoint = p.floor();
    double weight = p - intPoint;

    if (closed) {
      intPoint += intPoint > 0 ? 0 : ((intPoint.abs() / l).floor() + 1) * l;
    } else if (weight == 0 && intPoint == l - 1) {
      intPoint = l - 2;
      weight = 1;
    }

    Vector3 p0;
    Vector3 p3; // 4 points (p1 & p2 defined below)

    if (closed || intPoint > 0) {
      p0 = points[(intPoint - 1) % l] as Vector3;
    } 
    else {
      // extrapolate first point
      tmp.sub2(points[0], points[1]).add(points[0]);
      p0 = tmp;
    }

    final Vector3 p1 = points[intPoint % l] as Vector3;
    final Vector3 p2 = points[(intPoint + 1) % l] as Vector3;

    if (closed || intPoint + 2 < l) {
      p3 = points[(intPoint + 2) % l] as Vector3;
    } 
    else {
      // extrapolate last point
      tmp.sub2(points[l - 1], points[l - 2]).add(points[l - 1]);
      p3 = tmp;
    }

    if (curveType == 'centripetal' || curveType == 'chordal') {
      // init Centripetal / Chordal Catmull-Rom
      final pow = curveType == 'chordal' ? 0.5 : 0.25;
      double dt0 = math.pow(p0.distanceToSquared(p1), pow).toDouble();
      double dt1 = math.pow(p1.distanceToSquared(p2), pow).toDouble();
      double dt2 = math.pow(p2.distanceToSquared(p3), pow).toDouble();

      // safety check for repeated points
      if (dt1 < 1e-4) dt1 = 1.0;
      if (dt0 < 1e-4) dt0 = dt1;
      if (dt2 < 1e-4) dt2 = dt1;

      px.initNonuniformCatmullRom(p0.x, p1.x, p2.x, p3.x, dt0, dt1, dt2);
      py.initNonuniformCatmullRom(p0.y, p1.y, p2.y, p3.y, dt0, dt1, dt2);
      pz.initNonuniformCatmullRom(p0.z, p1.z, p2.z, p3.z, dt0, dt1, dt2);
    } 
    else if (curveType == 'catmullrom') {
      px.initCatmullRom(p0.x, p1.x, p2.x, p3.x, tension);
      py.initCatmullRom(p0.y, p1.y, p2.y, p3.y, tension);
      pz.initCatmullRom(p0.z, p1.z, p2.z, p3.z, tension);
    }

    point.setValues(px.calc(weight), py.calc(weight), pz.calc(weight));

    return point;
  }

  @override
  CatmullRomCurve3 clone() {
    return CatmullRomCurve3()..copy(this);
  }

  @override
  CatmullRomCurve3 copy(Curve source) {
    if(source is CatmullRomCurve3){
      super.copy(source);

      points = [];

      for (int i = 0, l = source.points.length; i < l; i++) {
        final point = source.points[i];
        points.add(point.clone());
      }

      closed = source.closed;
      curveType = source.curveType;
      tension = source.tension;
    }

    return this;
  }

  // toJSON() {

  //   final data = Curve.prototype.toJSON.call( this );

  //   data.points = [];

  //   for ( int i = 0, l = this.points.length; i < l; i ++ ) {

  //     final point = this.points[ i ];
  //     data.points.push( point.toArray() );

  //   }

  //   data.closed = this.closed;
  //   data.curveType = this.curveType;
  //   data.tension = this.tension;

  //   return data;

  // }

  // fromJSON( json ) {

  //   Curve.prototype.fromJSON.call( this, json );

  //   this.points = [];

  //   for ( int i = 0, l = json.points.length; i < l; i ++ ) {

  //     final point = json.points[ i ];
  //     this.points.push( new Vector3().fromArray( point ) );

  //   }

  //   this.closed = json.closed;
  //   this.curveType = json.curveType;
  //   this.tension = json.tension;

  //   return this;

  // }

}
