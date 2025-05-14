import 'package:three_js_curves/three_js_curves.dart';
import 'package:three_js_math/three_js_math.dart';

import './parametric.dart';
import 'dart:math' as math;

enum ParametricGeometriesType{kline,plane,mobius,mobius3d}

/**
 * Experimenting of primitive geometry creation using Surface Parametric equations
 */

class ParametricGeometries{
	static void klein(double v, double u, Vector3 target ) {
		u *= math.pi;
		v *= 2 * math.pi;

		u = u * 2;
		double x, z;
		if ( u < math.pi ) {
			x = 3 * math.cos( u ) * ( 1 + math.sin( u ) ) + ( 2 * ( 1 - math.cos( u ) / 2 ) ) * math.cos( u ) * math.cos( v );
			z = - 8 * math.sin( u ) - 2 * ( 1 - math.cos( u ) / 2 ) * math.sin( u ) * math.cos( v );
		} else {
			x = 3 * math.cos( u ) * ( 1 + math.sin( u ) ) + ( 2 * ( 1 - math.cos( u ) / 2 ) ) * math.cos( v + math.pi );
			z = - 8 * math.sin( u );
		}

		final y = - 2 * ( 1 - math.cos( u ) / 2 ) * math.sin( v );

		target.setValues( x, y, z );
	}

	static Function(double u,double v, Vector3 target) plane(double width,double height ) {
		return(double u,double v, Vector3 target ) {
			final x = u * width;
			final y = 0.0;
			final z = v * height;

			target.setValues( x, y, z );
		};
	}

	static void mobius(double u,double t, Vector3 target ) {

		// flat mobius strip
		// http://www.wolframalpha.com/input/?i=M%C3%B6bius+strip+parametric+equations&lk=1&a=ClashPrefs_*Surface.MoebiusStrip.SurfaceProperty.ParametricEquations-
		u = u - 0.5;
		final v = 2 * math.pi * t;

		const a = 2;

		final x = math.cos( v ) * ( a + u * math.cos( v / 2 ) );
		final y = math.sin( v ) * ( a + u * math.cos( v / 2 ) );
		final z = u * math.sin( v / 2 );

		target.setValues( x, y, z );
	}

	static void mobius3d(double u,double t, Vector3 target ) {
		u *= math.pi;
		t *= 2 * math.pi;

		u = u * 2;
		double phi = u / 2;
		const major = 2.25, a = 0.125, b = 0.65;

		double x = a * math.cos( t ) * math.cos( phi ) - b * math.sin( t ) * math.sin( phi );
		final z = a * math.cos( t ) * math.sin( phi ) + b * math.sin( t ) * math.cos( phi );
		final y = ( major + x ) * math.sin( u );
		x = ( major + x ) * math.cos( u );

		target.setValues( x, y, z );
	}
}


/*********************************************
 *
 * Parametric Replacement for TubeGeometry
 *
 *********************************************/

class ParametricTubeGeometry extends ParametricGeometry {
  ParametricTubeGeometry.init(super.func, super.slices, super.stacks);
  factory ParametricTubeGeometry(Curve path, [int segments = 64, double radius = 1, int segmentsRadius = 8, bool closed = false ]) {
    return fromPath(path,segments,radius,segments,closed);
  }
	static ParametricTubeGeometry fromPath(Curve path, [int segments = 64, double radius = 1, int segmentsRadius = 8, bool closed = false ]) {
		final numpoints = segments + 1;

		final frames = path.computeFrenetFrames( segments, closed ),
			//tangents = frames.tangents,
			normals = frames.normals,
			binormals = frames.binormals;

		final position = new Vector3();

		parametricTube(double u, double v, Vector3 target ) {
			v *= 2 * math.pi;

			final i = ( u * ( numpoints - 1 ) ).floor();

			path.getPointAt( u, position );

			final normal = normals![ i ];
			final binormal = binormals![ i ];

			final cx = - radius * math.cos( v ); // TODO: Hack: Negating it so it faces outside.
			final cy = radius * math.sin( v );

			position.x += cx * normal.x + cy * binormal.x;
			position.y += cx * normal.y + cy * binormal.y;
			position.z += cx * normal.z + cy * binormal.z;

			target.setFrom( position );
		}

		return ParametricTubeGeometry.init( parametricTube, segments, segmentsRadius );

		// proxy internals

		// this.tangents = tangents;
		// this.normals = normals;
		// this.binormals = binormals;
	}
}

class ParametricTorusKnotCurve extends Curve {
  double q;
  double p;
  double radius;

  ParametricTorusKnotCurve(this.q,this.p,this.radius);

  getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    final point = optionalTarget;

    t *= math.pi * 2;

    const r = 0.5;

    final x = ( 1 + r * math.cos( q * t ) ) * math.cos( p * t );
    final y = ( 1 + r * math.cos( q * t ) ) * math.sin( p * t );
    final z = r * math.sin( q * t );

    return (point as Vector3).setValues( x, y, z ).scale( radius );
  }
}

/*********************************************
  *
  * Parametric Replacement for TorusKnotGeometry
  *
  *********************************************/
class ParametricTorusKnotGeometry extends ParametricTubeGeometry {
  ParametricTorusKnotGeometry.init(Function(double,double,Vector3) func, int slices, int stacks):super.init(func, slices, stacks);//.init(super.path,super.segments,super.radius,super.segmentsRadius,super.closed);
  
	factory ParametricTorusKnotGeometry([double radius = 200, double tube = 40, int segmentsT = 64, int segmentsR = 8, double p = 2, double q = 3] ) {
		final segments = segmentsT;
		final radiusSegments = segmentsR;
		final extrudePath = new ParametricTorusKnotCurve(q,p,radius);

		ParametricTubeGeometry ptg = ParametricTubeGeometry.fromPath(extrudePath, segments, tube, radiusSegments, true);
    final t = ParametricTorusKnotGeometry.init(ptg.func,ptg.slices,ptg.stacks);
    ptg.dispose();
    return t;
		// this.radius = radius;
		// this.tube = tube;
		// this.segmentsT = segmentsT;
		// this.segmentsR = segmentsR;
		// this.p = p;
		// this.q = q;
	}
}

/*********************************************
  *
  * Parametric Replacement for SphereGeometry
  *
  *********************************************/
class ParametricSphereGeometry extends ParametricGeometry {
  ParametricSphereGeometry.init(super.func,super.slices,super.stacks);
	factory ParametricSphereGeometry(num size, int u, int v ) {
		sphere(double u,double v,Vector3 target ) {
			u *= math.pi;
			v *= 2 * math.pi;

			final x = size * math.sin( u ) * math.cos( v );
			final y = size * math.sin( u ) * math.sin( v );
			final z = size * math.cos( u );

			target.setValues( x, y, z );
		}

		return ParametricSphereGeometry.init( sphere, u, v );
	}
}


/*********************************************
  *
  * Parametric Replacement for PlaneGeometry
  *
  *********************************************/

class ParametricPlaneGeometry extends ParametricGeometry {
  ParametricPlaneGeometry.init(super.func,super.slices,super.stacks);
	factory ParametricPlaneGeometry( width, depth, segmentsWidth, segmentsDepth ) {

		plane(double u, double v, Vector3 target ) {
			final x = u * width;
			final y = 0.0;
			final z = v * depth;

			target.setValues( x, y, z );
		}

		return ParametricPlaneGeometry.init( plane, segmentsWidth, segmentsDepth );
	}
}
