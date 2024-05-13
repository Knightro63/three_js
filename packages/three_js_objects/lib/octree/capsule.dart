import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';

class Capsule{
	Capsule([
    Vector3? start, 
    Vector3? end, 
    double? radius
  ]){
    this.start = start ?? Vector3( 0, 0, 0 );
    this.end = end ?? Vector3( 0, 1, 0 );
    this.radius = radius ?? 1;
  }

	Vector3 _v1 = Vector3();
	Vector3 _v2 = Vector3();
	Vector3 _v3 = Vector3();

	double EPS = 1e-10;

  late Vector3 start;
  late Vector3 end;
  late double radius;

  Capsule clone(){
    return Capsule(start.clone(), end.clone(), radius);
  }

  void set(Vector3 start, Vector3 end, double radius){
    this.start.setFrom(start);
    this.end.setFrom(end);
    this.radius = radius;
  }
  void copy(Capsule capsule){
    start.setFrom(capsule.start);
    end.setFrom(capsule.end);
    radius = capsule.radius;
  }
  void translate(Vector3 v){
    start.add(v);
    end.add(v);
  }

  bool checkAABBAxis(double p1x,double p1y,double p2x,double p2y,double minx,double maxx,double miny,double maxy, double radius){
    return (
      ( minx - p1x < radius || minx - p2x < radius ) &&
      ( p1x - maxx < radius || p2x - maxx < radius ) &&
      ( miny - p1y < radius || miny - p2y < radius ) &&
      ( p1y - maxy < radius || p2y - maxy < radius )
    );
  }
  bool intersectsBox(BoundingBox box){
    return (
      checkAABBAxis(
        start.x, start.y, end.x, end.y,
        box.min.x, box.max.x, box.min.y, box.max.y,
        radius 
      ) &&
      checkAABBAxis(
        start.x, start.z, end.x, end.z,
        box.min.x, box.max.x, box.min.z, box.max.z,
        radius 
      ) &&
      checkAABBAxis(
        start.y, start.z, end.y, end.z,
        box.min.y, box.max.y, box.min.z, box.max.z,
        radius 
      )
    );
  }
  
  Vector3 getCenter(Vector3 target){
    return target.setFrom(end).add(start).scale( 0.5 );
  }
  List<Vector3> lineLineMinimumPoints( line1, line2 ){
    Vector3 r = _v1.setFrom( line1.end ).sub( line1.start );
    Vector3 s = _v2.setFrom( line2.end ).sub( line2.start );
    Vector3 w = _v3.setFrom( line2.start ).sub( line1.start );

    num a = r.dot( s ),
      b = r.dot( r ),
      c = s.dot( s ),
      d = s.dot( w ),
      e = r.dot( w );

    double t1; 
    double t2;
    num divisor = b * c - a * a;

    if(divisor.abs() < EPS ) {
      double d1 = - d / c;
      double d2 = ( a - d ) / c;

      if(( d1 - 0.5 ).abs() < (d2 - 0.5).abs() ) {
        t1 = 0;
        t2 = d1;
      } 
      else {
        t1 = 1;
        t2 = d2;
      }
    } 
    else {
      t1 = ( d * a + e * c ) / divisor;
      t2 = ( t1 * a - d ) / c;
    }

    t2 = math.max( 0, math.min( 1, t2 ) );
    t1 = math.max( 0, math.min( 1, t1 ) );

    Vector3 point1 = r.scale( t1 ).add( line1.start );
    Vector3 point2 = s.scale( t2 ).add( line2.start );

    return [point1, point2];
  }
}