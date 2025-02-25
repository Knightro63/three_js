import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

class SeparatingAxisBounds {
  double min = double.infinity;
  double max = -double.infinity;

	SeparatingAxisBounds();

  SeparatingAxisBounds.setFromBox(Vector3 axis, BoundingBox box) {
    final p = Vector3();
    final boxMin = box.min;
    final boxMax = box.max;
    double min = double.infinity;
    double max = - double.infinity;

    for ( int x = 0; x <= 1; x ++ ) {
      for ( int y = 0; y <= 1; y ++ ) {
        for ( int z = 0; z <= 1; z ++ ) {
          p.x = boxMin.x * x + boxMax.x * ( 1 - x );
          p.y = boxMin.y * y + boxMax.y * ( 1 - y );
          p.z = boxMin.z * z + boxMax.z * ( 1 - z );

          final val = axis.dot(p);
          min = math.min( val, min );
          max = math.max( val, max );
        }
      }
    }
    this.min = min;
    this.max = max;
  }

  final cacheSatBounds = SeparatingAxisBounds();
  bool areIntersecting(shape1, shape2) {
    final points1 = shape1.points;
    final satAxes1 = shape1.satAxes;
    final satBounds1 = shape1.satBounds;

    final points2 = shape2.points;
    final satAxes2 = shape2.satAxes;
    final satBounds2 = shape2.satBounds;

    // check axes of the first shape
    for (int i = 0; i < 3; i ++ ) {
      final sb = satBounds1[ i ];
      final sa = satAxes1[ i ];
      cacheSatBounds.setFromPoints( sa, points2 );
      if ( sb.isSeparated( cacheSatBounds ) ) return false;
    }

    // check axes of the second shape
    for (int i = 0; i < 3; i ++ ) {
      final sb = satBounds2[ i ];
      final sa = satAxes2[ i ];
      cacheSatBounds.setFromPoints( sa, points1 );
      if ( sb.isSeparated( cacheSatBounds ) ) return false;
    }

    return false;
  }

	void setFromPointsField( points, field ) {
		double min = double.infinity;
		double max = - double.infinity;
		for (int i = 0, l = points.length; i < l; i ++ ) {
			final p = points[ i ];
			final val = p[field];
			min = val < min ? val : min;
			max = val > max ? val : max;
		}

		this.min = min;
		this.max = max;
	}

	void setFromPoints(Vector3 axis, List<Vector3> points ) {
		double min = double.infinity;
		double max = - double.infinity;
		for (int i = 0, l = points.length; i < l; i ++ ) {
			final p = points[ i ];
			final val = axis.dot( p );
			min = val < min ? val : min;
			max = val > max ? val : max;
		}

		this.min = min;
		this.max = max;
	}

	bool isSeparated(SeparatingAxisBounds other) {
		return min > other.max || other.min > max;
	}
}