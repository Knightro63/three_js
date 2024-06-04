import 'nurbs_utils.dart' as utils;
import 'package:three_js_math/three_js_math.dart';
import '../core/curve.dart';

/// *
/// * NURBS curve object
/// *
/// * Derives from Curve, overriding getPoint and getTangent.
/// *
/// * Implementation is based on (x, y [, z=0 [, w=1]]) control points with w=weight.
/// *
/// *

class NURBSCurve extends Curve {
  int degree;
  List<double> knots;
  late List<Vector4> controlPoints;
  late int startKnot;
  late int endKnot;

	NURBSCurve(
		this.degree,
		this.knots /* array of reals */,
		List<Vector> controlPoints /* array of Vector(2|3|4) */,
  [
		int? startKnot /* index in knots */,
		int? endKnot /* index in knots */
	]) : super() {

		this.controlPoints = [];
		// Used by periodic NURBS to remove hidden spans
		this.startKnot = startKnot ?? 0;
		this.endKnot = endKnot ?? (knots.length - 1 );

		for(int i = 0; i < controlPoints.length; i++) {
			// ensure Vector4 for control points
			final point = controlPoints[i];
      if(point is Vector4){
        this.controlPoints.add(Vector4(point.x, point.y, point.z, point.w));
      }
      else if(point is Vector3){
        this.controlPoints.add(Vector4(point.x, point.y, point.z));
      }
      else{
        this.controlPoints.add(Vector4(point.x, point.y));
      }
			
		}
	}

  @override
	Vector3 getPoint(num t, [Vector? optionalTarget]) {
    if(optionalTarget == null || optionalTarget is! Vector3){
      if(optionalTarget == null){
        optionalTarget = Vector3();
      }
      else if(optionalTarget is Vector4){
        optionalTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
      }
      else{
        optionalTarget = Vector3(optionalTarget.x,optionalTarget.y);
      }
    }
		Vector3 point = optionalTarget;

		final u = knots[startKnot ] + t * (knots[endKnot ] - knots[startKnot ] ); // linear mapping t->u

		// following results in (wx, wy, wz, w) homogeneous point
		Vector4 hpoint = utils.calcBSplinePoint(degree,knots,controlPoints, u );

		if ( hpoint.w != 1.0 ) {

			// project to 3D space: (wx, wy, wz, w) -> (x, y, z, 1)
			hpoint.divideScalar( hpoint.w );

		}

		return point.setValues( hpoint.x, hpoint.y, hpoint.z );
	}

  @override
	Vector getTangent(num t, [Vector? optionalTarget]) {
		final tangent = optionalTarget ?? Vector3() ;
		final u = knots[ 0 ] + t * ( knots[knots.length - 1 ] - knots[ 0 ] );
		final ders = utils.calcNURBSDerivatives(degree, knots, controlPoints, u, 1 );
		tangent.setFrom( ders[ 1 ] ).normalize();
		return tangent;
	}
}
