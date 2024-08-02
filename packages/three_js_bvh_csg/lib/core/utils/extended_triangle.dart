import 'dart:ffi';

import 'package:three_js_bvh_csg/core/utils/seperating_axis_bounds.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

const zeroEpsilon = 1e-15;

bool isNearZero(double value) {
	return value.abs() < zeroEpsilon;
}

class ExtendedTriangle extends Triangle {
  bool isExtendedTriangle = true;
  late List<Vector3> satAxes; 
  late List<Vector3> points;
  BoundingSphere sphere = BoundingSphere();
  Plane plane = Plane();
  bool needsUpdate = true;
  List<SeparatingAxisBounds> satBounds = [];

	ExtendedTriangle([super.a,super.b,super.c]):super(){
		satAxes = [Vector3.zero(),Vector3.zero(),Vector3.zero(),Vector3.zero()];
		satBounds = [SeparatingAxisBounds(),SeparatingAxisBounds(),SeparatingAxisBounds(),SeparatingAxisBounds()];
		points = [a, b, c ];
	}

	intersectsSphere(BoundingSphere sphere ) {
		return sphereIntersectTriangle( sphere, this );
	}

	void update() {
		final a = this.a;
		final b = this.b;
		final c = this.c;
		final points = this.points;

		final satAxes = this.satAxes;
		final satBounds = this.satBounds;

		final axis0 = satAxes[ 0 ];
		final sab0 = satBounds[ 0 ];
		getNormal( axis0 );
		sab0.setFromPoints( axis0, points );

		final axis1 = satAxes[ 1 ];
		final sab1 = satBounds[ 1 ];
		axis1.sub2( a, b );
		sab1.setFromPoints( axis1, points );

		final axis2 = satAxes[ 2 ];
		final sab2 = satBounds[ 2 ];
		axis2.sub2( b, c );
		sab2.setFromPoints( axis2, points );

		final axis3 = satAxes[ 3 ];
		final sab3 = satBounds[ 3 ];
		axis3.sub2( c, a );
		sab3.setFromPoints( axis3, points );

		sphere.setFromPoints( this.points );
		plane.setFromNormalAndCoplanarPoint( axis0, a );
		needsUpdate = false;
	}

  final point1 = Vector3();
  final point2 = Vector3();
  final edge = Line3();
  double closestPointToSegment(segment, [target1, target2]){
    final start = segment.start;
    final end = segment.end;
    final points = this.points;
    double distSq;
    double closestDistanceSq = double.infinity;

    // check the triangle edges
    for (int i = 0; i < 3; i ++ ) {
      final nexti = ( i + 1 ) % 3;
      edge.start.setFrom( points[ i ] );
      edge.end.setFrom( points[ nexti ] );

      closestPointsSegmentToSegment( edge, segment, point1, point2 );

      distSq = point1.distanceToSquared( point2 );
      if ( distSq < closestDistanceSq ) {
        closestDistanceSq = distSq;
        if ( target1 ) target1.copy( point1 );
        if ( target2 ) target2.copy( point2 );
      }
    }

    // check end points
    closestPointToPoint( start, point1 );
    distSq = start.distanceToSquared( point1 );
    if ( distSq < closestDistanceSq ) {
      closestDistanceSq = distSq;
      if ( target1 ) target1.copy( point1 );
      if ( target2 ) target2.copy( start );
    }

    closestPointToPoint( end, point1 );
    distSq = end.distanceToSquared( point1 );
    if ( distSq < closestDistanceSq ) {
      closestDistanceSq = distSq;
      if ( target1 ) target1.copy( point1 );
      if ( target2 ) target2.copy( end );
    }

    return math.sqrt( closestDistanceSq );
  }

  final saTri2 = ExtendedTriangle();
  final arr1 = [Vector3(),Vector3(),Vector3()];
  final arr2 = [Vector3(),Vector3(),Vector3()];
  final cachedSatBounds = SeparatingAxisBounds();
  final cachedSatBounds2 = SeparatingAxisBounds();
  final cachedAxis = Vector3();
  final dir = Vector3();
  final dir1 = Vector3();
  final dir2 = Vector3();
  final tempDir = Vector3();
  final edge1 = Line3();
  final edge2 = Line3();
  final tempPoint = Vector3();
  intersectsTriangle(tri, plane, targetEdge){
      // find the edge that intersects the other triangle plane
      final points = tri.points;
      int count = 0;
      int startPointIntersection = - 1;

      for (int i = 0; i < 3; i ++ ) {

        final start = edge.start;
        final end = edge.end;
        start.setFrom( points[ i ] );
        end.setFrom( points[ ( i + 1 ) % 3 ] );
        edge.delta( dir );

        final startIntersects = isNearZero( plane.distanceToPoint( start ) );
        if ( isNearZero( plane.normal.dot( dir ) ) && startIntersects ) {
          // if the edge lies on the plane then take the line
          targetEdge.copy( edge );
          count = 2;
          break;
        }

        // check if the start point is near the plane because "intersectLine" is not robust to that case
        final doesIntersect = plane.intersectLine( edge, tempPoint );
        if ( ! doesIntersect && startIntersects ) {
          tempPoint.setFrom( start );
        }

        // ignore the end point
        if ( ( doesIntersect || startIntersects ) && ! isNearZero( tempPoint.distanceTo( end ) ) ) {
          if ( count <= 1 ) {
            // assign to the start or end point and save which index was snapped to
            // the start point if necessary
            final point = count == 1 ? targetEdge.start : targetEdge.end;
            point.copy( tempPoint );
            if ( startIntersects ) {
              startPointIntersection = count;
            }
          } else if ( count >= 2 ) {
            // if we're here that means that there must have been one point that had
            // snapped to the start point so replace it here
            final point = startPointIntersection == 1 ? targetEdge.start : targetEdge.end;
            point.copy( tempPoint );
            count = 2;
            break;
          }

          count ++;
          if ( count == 2 && startPointIntersection == - 1 ) {
            break;
          }
        }
      }

      return count;
    }

    // TODO: If the triangles are coplanar and intersecting the target is nonsensical. It should at least
    // be a line contained by both triangles if not a different special case somehow represented in the return result.
    return function intersectsTriangle( other, [target, suppressLog = false] ) {

      if (needsUpdate ) {
        update();
      }

      if ( ! other.isExtendedTriangle ) {

        saTri2.copy( other );
        saTri2.update();
        other = saTri2;

      } else if ( other.needsUpdate ) {

        other.update();

      }

      final plane1 = plane;
      final plane2 = other.plane;

      if ( ( plane1.normal.dot( plane2.normal ) ).abs() > 1.0 - 1e-10 ) {

        // perform separating axis intersection test only for coplanar triangles
        final satBounds1 = satBounds;
        final satAxes1 = satAxes;
        arr2[ 0 ] = other.a;
        arr2[ 1 ] = other.b;
        arr2[ 2 ] = other.c;
        for (int i = 0; i < 4; i ++ ) {
          final sb = satBounds1[ i ];
          final sa = satAxes1[ i ];
          cachedSatBounds.setFromPoints( sa, arr2 );
          if ( sb.isSeparated( cachedSatBounds ) ) return false;
        }

        final satBounds2 = other.satBounds;
        final satAxes2 = other.satAxes;
        arr1[ 0 ] = a;
        arr1[ 1 ] = b;
        arr1[ 2 ] = c;

        for (int i = 0; i < 4; i ++ ) {
          final sb = satBounds2[ i ];
          final sa = satAxes2[ i ];
          cachedSatBounds.setFromPoints( sa, arr1 );
          if ( sb.isSeparated( cachedSatBounds ) ) return false;
        }

        // check crossed axes
        for (int i = 0; i < 4; i ++ ) {
          final sa1 = satAxes1[ i ];
          for (Int i2 = 0; i2 < 4; i2 ++ ) {
            final sa2 = satAxes2[ i2 ];
            cachedAxis.cross2( sa1, sa2 );
            cachedSatBounds.setFromPoints( cachedAxis, arr1 );
            cachedSatBounds2.setFromPoints( cachedAxis, arr2 );
            if ( cachedSatBounds.isSeparated( cachedSatBounds2 ) ) return false;
          }
        }

        if ( target != null) {
          // TODO find two points that intersect on the edges and make that the result
          if (!suppressLog ) {
            console.warning( 'ExtendedTriangle.intersectsTriangle: Triangles are coplanar which does not support an output edge. Setting edge to 0, 0, 0.' );
          }

          target.start.set( 0, 0, 0 );
          target.end.set( 0, 0, 0 );
        }

        return true;

      } else {

        // find the edge that intersects the other triangle plane
        final count1 = triIntersectPlane( this, plane2, edge1 );
        if ( count1 == 1 && other.containsPoint( edge1.end ) ) {

          if ( target ) {

            target.start.copy( edge1.end );
            target.end.copy( edge1.end );

          }

          return true;

        } else if ( count1 != 2 ) {

          return false;

        }

        // find the other triangles edge that intersects this plane
        final count2 = triIntersectPlane( other, plane1, edge2 );
        if ( count2 == 1 && this.containsPoint( edge2.end ) ) {

          if ( target ) {

            target.start.copy( edge2.end );
            target.end.copy( edge2.end );

          }

          return true;
        } else if ( count2 != 2 ) {
          return false;
        }

        // find swap the second edge so both lines are running the same direction
        edge1.delta( dir1 );
        edge2.delta( dir2 );

        if ( dir1.dot( dir2 ) < 0 ) {
          final tmp = edge2.start;
          edge2.start = edge2.end;
          edge2.end = tmp;
        }

        // check if the edges are overlapping
        final s1 = edge1.start.dot( dir1 );
        final e1 = edge1.end.dot( dir1 );
        final s2 = edge2.start.dot( dir1 );
        final e2 = edge2.end.dot( dir1 );
        final separated1 = e1 < s2;
        final separated2 = s1 < e2;

        if ( s1 != e2 && s2 != e1 && separated1 == separated2 ) {

          return false;

        }

        // assign the target output
        if ( target ) {

          tempDir.sub2( edge1.start, edge2.start );
          if ( tempDir.dot( dir1 ) > 0 ) {

            target.start.copy( edge1.start );

          } else {

            target.start.copy( edge2.start );

          }

          tempDir.sub2( edge1.end, edge2.end );
          if ( tempDir.dot( dir1 ) < 0 ) {
            target.end.copy( edge1.end );
          } else {
            target.end.copy( edge2.end );
          }
        }

        return true;
      }
    }
  }

  final target = Vector3();
  double distanceToPoint(point){
    closestPointToPoint( point, target );
    return point.distanceTo( target );
  }

  final point = Vector3();
  final point2 = Vector3();
  final cornerFields = [ 'a', 'b', 'c' ];
  final line1 = Line3();
  final line2 = Line3();
  double distanceToTriangle(other, [target1, target2]){
    final lineTarget = target1 || target2 ? line1 : null;
    if (intersectsTriangle( other, lineTarget ) ) {
      if ( target1 || target2 ) {
        if ( target1 ) lineTarget?.getCenter( target1 );
        if ( target2 ) lineTarget?.getCenter( target2 );
      }

      return 0;
    }

    double closestDistanceSq = double.infinity;

    // check all point distances
    for (int i = 0; i < 3; i ++ ) {
      double dist;
      final field = cornerFields[ i ];
      final otherVec = other[ field ];
      closestPointToPoint( otherVec, point );

      dist = otherVec.distanceToSquared( point );

      if ( dist < closestDistanceSq ) {
        closestDistanceSq = dist;
        if ( target1 ) target1.copy( point );
        if ( target2 ) target2.copy( otherVec );
      }

      final thisVec = this[ field ];
      other.closestPointToPoint( thisVec, point );
      dist = thisVec.distanceToSquared( point );

      if ( dist < closestDistanceSq ) {
        closestDistanceSq = dist;
        if ( target1 ) target1.copy( thisVec );
        if ( target2 ) target2.copy( point );
      }
    }

    for (int i = 0; i < 3; i ++ ) {
      final f11 = cornerFields[ i ];
      final f12 = cornerFields[ ( i + 1 ) % 3 ];
      line1.setValues( this[ f11 ], this[ f12 ] );
      for (int i2 = 0; i2 < 3; i2 ++ ) {

        final f21 = cornerFields[ i2 ];
        final f22 = cornerFields[ ( i2 + 1 ) % 3 ];
        line2.setValues( other[ f21 ], other[ f22 ] );

        closestPointsSegmentToSegment( line1, line2, point, point2 );

        final dist = point.distanceToSquared( point2 );
        if ( dist < closestDistanceSq ) {
          closestDistanceSq = dist;
          if ( target1 ) target1.copy( point );
          if ( target2 ) target2.copy( point2 );
        }
      }
    }

    return math.sqrt( closestDistanceSq );
  }
}