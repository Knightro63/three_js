import 'package:three_js_math/three_js_math.dart';
import 'nurbs_utils.dart';

/**
 * NURBS surface object
 *
 * Implementation is based on (x, y [, z=0 [, w=1]]) control points with w=weight.
 **/

class NURBSSurface {
  List<List<Vector4>> controlPoints;
  List<double> knots1;
  List<double> knots2;
  int degree1;
  int degree2;

	NURBSSurface(this.degree1, this.degree2, this.knots1, this.knots2, this.controlPoints) {
		final len1 = knots1.length - degree1 - 1;
		final len2 = knots2.length - degree2 - 1;

		// ensure Vector4 for control points
		for (int i = 0; i < len1; ++ i ) {
			//controlPoints[i] = [];
			for (int j = 0; j < len2; ++ j ) {
				final point = controlPoints[ i ][ j ];
        controlPoints[ i ][ j ] = Vector4( point.x, point.y, point.z, point.w );
			}
		}
	}

	void getPoint(double t1, double t2,Vector target ) {
		final u = knots1[ 0 ] + t1 * ( knots1[ knots1.length - 1 ] - knots1[ 0 ] ); // linear mapping t1->u
		final v = knots2[ 0 ] + t2 * ( knots2[ knots2.length - 1 ] - knots2[ 0 ] ); // linear mapping t2->u

		NURBSutils.calcSurfacePoint( degree1, degree2, knots1, knots2, controlPoints, u, v, target );
	}
}