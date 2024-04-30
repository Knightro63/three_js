/// *
/// * NURBS utils
/// *
/// * See NURBSCurve and NURBSSurface.
/// *

import 'package:three_js_math/three_js_math.dart';

/*
Finds knot vector span.

p : degree
u : parametric value
U : knot vector

returns the span
*/
int findSpan(int p, int u, List<double> U ) {
	final n = U.length - p - 1;

	if ( u >= U[ n ] ) {
		return n - 1;
	}

	if ( u <= U[ p ] ) {
		return p;
	}

	num low = p;
	num high = n;
	int mid = ( ( low + high ) / 2 ).floor();

	while ( u < U[ mid ] || u >= U[ mid + 1 ] ) {
		if ( u < U[ mid ] ) {
			high = mid;
		} 
    else {
			low = mid;
		}
		mid = ( ( low + high ) / 2 ).floor();
	}

	return mid;
}


/*
Calculate basis functions. See The NURBS Book, page 70, algorithm A2.2

span : span in which u lies
u    : parametric point
p    : degree
U    : knot vector

returns array[p+1] with basis functions values.
*/
List<double> calcBasisFunctions(int span, int u, int p, List<double> U ) {
	final List<double> N = [];
	final left = [];
	final right = [];
	N[0] = 1.0;

	for (int j = 1; j <= p; ++ j ) {
		left[ j ] = u - U[ span + 1 - j ];
		right[ j ] = U[ span + j ] - u;

		double saved = 0.0;

		for (int r = 0; r < j; ++ r ) {
			final rv = right[ r + 1 ];
			final lv = left[ j - r ];
			final temp = N[ r ] / ( rv + lv );
			N[r] = saved + rv * temp;
			saved = lv * temp;
		}

		N[j] = saved;
	}

	return N;
}


/*
Calculate B-Spline curve points. See The NURBS Book, page 82, algorithm A3.1.

p : degree of B-Spline
U : knot vector
P : control points (x, y, z, w)
u : parametric point

returns point for given u
*/
Vector4 calcBSplinePoint( p, U, P, u ) {
	final span = findSpan( p, u, U );
	final N = calcBasisFunctions( span, u, p, U );
	final C = Vector4( 0, 0, 0, 0 );

	for (int j = 0; j <= p; j++) {
		final point = P[ span - p + j ];
		final nj = N[ j ];
		final wNj = point.w * nj;
		C.x += point.x * wNj;
		C.y += point.y * wNj;
		C.z += point.z * wNj;
		C.w += point.w * nj;
	}

	return C;
}


/*
Calculate basis functions derivatives. See The NURBS Book, page 72, algorithm A2.3.

span : span in which u lies
u    : parametric point
p    : degree
n    : number of derivatives to calculate
U    : knot vector

returns array[n+1][p+1] with basis functions derivatives
*/
List<List<double>> calcBasisFunctionDerivatives(int span, u, int p, int n, List<double> U ) {

	final List<double> zeroArr = [];
	for ( int i = 0; i <= p; ++ i ){
		zeroArr[ i ] = 0.0;
  }

	final List<List<double>> ders = [];

	for ( int i = 0; i <= n; ++ i ){
		ders[ i ] = zeroArr.sublist( 0 );
  }

	final ndu = [];

	for ( int i = 0; i <= p; ++ i ){
		ndu[ i ] = zeroArr.sublist( 0 );
  }

	ndu[ 0 ][ 0 ] = 1.0;

	final List<double> left = zeroArr.sublist( 0 );
	final List<double> right = zeroArr.sublist( 0 );

	for ( int j = 1; j <= p; ++ j ) {
		left[ j ] = u - U[ span + 1 - j ];
		right[ j ] = U[ span + j ] - u;

		double saved = 0.0;

		for ( int r = 0; r < j; ++ r ) {
			final rv = right[ r + 1 ];
			final lv = left[ j - r ];
			ndu[ j ][ r ] = rv + lv;

			final temp = ndu[ r ][ j - 1 ] / ndu[ j ][ r ];
			ndu[ r ][ j ] = saved + rv * temp;
			saved = lv * temp;
		}

		ndu[ j ][ j ] = saved;
	}

	for ( int j = 0; j <= p; ++ j ) {
		ders[ 0 ][ j ] = ndu[ j ][ p ];
	}

	for ( int r = 0; r <= p; ++ r ) {
		int s1 = 0;
		int s2 = 1;

		final a = [];
		for ( int i = 0; i <= p; ++ i ) {
			a[ i ] = zeroArr.sublist( 0 );
		}

		a[ 0 ][ 0 ] = 1.0;

		for ( int k = 1; k <= n; ++ k ) {
			double d = 0.0;
			final rk = r - k;
			final pk = p - k;

			if ( r >= k ) {
				a[ s2 ][ 0 ] = a[ s1 ][ 0 ] / ndu[ pk + 1 ][ rk ];
				d = a[ s2 ][ 0 ] * ndu[ rk ][ pk ];
			}

			final j1 = ( rk >= - 1 ) ? 1 : - rk;
			final j2 = ( r - 1 <= pk ) ? k - 1 : p - r;

			for ( int j = j1; j <= j2; ++ j ) {
				a[ s2 ][ j ] = ( a[ s1 ][ j ] - a[ s1 ][ j - 1 ] ) / ndu[ pk + 1 ][ rk + j ];
				d += a[ s2 ][ j ] * ndu[ rk + j ][ pk ];
			}

			if ( r <= pk ) {
				a[ s2 ][ k ] = - a[ s1 ][ k - 1 ] / ndu[ pk + 1 ][ r ];
				d += a[ s2 ][ k ] * ndu[ r ][ pk ];
			}

			ders[ k ][ r ] = d;

			final j = s1;
			s1 = s2;
			s2 = j;
		}
	}

	num r = p;

	for ( int k = 1; k <= n; ++ k ) {
		for ( int j = 0; j <= p; ++ j ) {
			ders[ k ][ j ] *= r;
		}
		r *= p - k;
	}

	return ders;
}


/*
	Calculate derivatives of a B-Spline. See The NURBS Book, page 93, algorithm A3.2.

	p  : degree
	U  : knot vector
	P  : control points
	u  : Parametric points
	nd : number of derivatives

	returns array[d+1] with derivatives
	*/
List<Vector4> calcBSplineDerivatives(int p,List<double> U, List<Vector> P, u, int nd ) {
	final du = nd < p ? nd : p;
	final List<Vector4> ck = [];
	int span = findSpan( p, u, U );
	final nders = calcBasisFunctionDerivatives( span, u, p, du, U );
	final List<Vector4> pw = [];

	for ( int i = 0; i < P.length; ++ i ) {
		final point = P[ i ].clone() as Vector4;
		final w = point.w;

		point.x *= w;
		point.y *= w;
		point.z *= w;

		pw[i] = point;
	}

	for ( int k = 0; k <= du; ++ k ) {
		final Vector4 point = pw[ span - p ].clone().scale( nders[ k ][ 0 ] );

		for ( int j = 1; j <= p; ++ j ) {
			point.add( pw[ span - p + j ].clone().scale( nders[ k ][ j ] ) );
		}

		ck[ k ] = point;
	}

	for ( int k = du + 1; k <= nd + 1; ++ k ) {
		ck[ k ] = Vector4( 0, 0, 0 );
	}

	return ck;
}


/*
Calculate "K over I"

returns k!/(i!(k-i)!)
*/
num calcKoverI( int k, int i ) {
	int nom = 1;

	for ( int j = 2; j <= k; ++ j ) {
		nom *= j;
	}

	int denom = 1;

	for ( int j = 2; j <= i; ++ j ) {
		denom *= j;
	}

	for ( int j = 2; j <= k - i; ++ j ) {
		denom *= j;
	}

	return nom / denom;
}


/*
Calculate derivatives (0-nd) of rational curve. See The NURBS Book, page 127, algorithm A4.2.

Pders : result of function calcBSplineDerivatives

returns array with derivatives for rational curve.
*/
List<Vector3> calcRationalCurveDerivatives(List<Vector4> pDers ) {
	final nd = pDers.length;
	final aDers = [];
	final wders = [];

	for ( int i = 0; i < nd; ++ i ) {
		final point = pDers[ i ];
		aDers[ i ] = Vector3( point.x, point.y, point.z );
		wders[ i ] = point.w;
	}

	final List<Vector3> ck = [];

	for ( int k = 0; k < nd; ++ k ) {
		final Vector3 v = aDers[ k ].clone();
		for ( int i = 1; i <= k; ++ i ) {
			v.sub( ck[ k - i ].clone().scale( calcKoverI( k, i ) * wders[ i ] ) );
		}
		ck[ k ] = v.divideScalar( wders[ 0 ] );
	}

	return ck;
}


/*
Calculate NURBS curve derivatives. See The NURBS Book, page 127, algorithm A4.2.

p  : degree
U  : knot vector
P  : control points in homogeneous space
u  : parametric points
nd : number of derivatives

returns array with derivatives.
*/
List<Vector3> calcNURBSDerivatives(int p, List<double> U, List<Vector> P, int u, int nd ) {
	final pDers = calcBSplineDerivatives( p, U, P, u, nd );
	return calcRationalCurveDerivatives( pDers );
}


/*
Calculate rational B-Spline surface point. See The NURBS Book, page 134, algorithm A4.3.

p1, p2 : degrees of B-Spline surface
U1, U2 : knot vectors
P      : control points (x, y, z, w)
u, v   : parametric values

returns point for given (u, v)
*/
void calcSurfacePoint( p, q, U, V, P, u, v, target ) {
	final uspan = findSpan( p, u, U );
	final vspan = findSpan( q, v, V );
	final nu = calcBasisFunctions( uspan, u, p, U );
	final nv = calcBasisFunctions( vspan, v, q, V );
	final temp = [];

	for ( int l = 0; l <= q; ++ l ) {
		temp[ l ] = Vector4( 0, 0, 0, 0 );
		for ( int k = 0; k <= p; ++ k ) {
			final point = P[ uspan - p + k ][ vspan - q + l ].clone();
			final w = point.w;
			point.x *= w;
			point.y *= w;
			point.z *= w;
			temp[ l ].add( point.multiplyScalar( nu[ k ] ) );
		}
	}

	Vector4 sw = Vector4( 0, 0, 0, 0 );
	for ( int l = 0; l <= q; ++ l ) {
		sw.add( temp[ l ].multiplyScalar( nv[ l ] ) );
	}

	sw.divideScalar( sw.w );
	target.set( sw.x, sw.y, sw.z );
}
