import "package:three_js_curves/core/curve.dart";
import "package:three_js_math/three_js_math.dart";
import 'dart:math' as math;


// GrannyKnot
class GrannyKnot extends Curve {
  @override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		t = 2 * math.pi * t;

		final x = - 0.22 * math.cos( t ) - 1.28 * math.sin( t ) - 0.44 * math.cos( 3 * t ) - 0.78 * math.sin( 3 * t );
		final y = - 0.1 * math.cos( 2 * t ) - 0.27 * math.sin( 2 * t ) + 0.38 * math.cos( 4 * t ) + 0.46 * math.sin( 4 * t );
		final z = 0.7 * math.cos( 3 * t ) - 0.4 * math.sin( 3 * t );

		return point.setValues( x, y, z ).scale( 20 );
	}
}

// HeartCurve

class HeartCurve extends Curve {
  double scale;
	HeartCurve([this.scale = 5 ]):super();

  @override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		t *= 2 * math.pi;

		final x = 16 * math.pow( math.sin( t ), 3 ).toDouble();
		final y = 13 * math.cos( t ) - 5 * math.cos( 2 * t ) - 2 * math.cos( 3 * t ) - math.cos( 4 * t );
		const z = 0.0;

		return point.setValues( x, y, z ).scale( scale );
	}
}

// Viviani's Curve

class VivianiCurve extends Curve {
  double scale;
	VivianiCurve([this.scale = 70 ]):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		t = t * 4 * math.pi; // normalized to 0..1
		final a = scale / 2;

		final x = a * ( 1 + math.cos( t ) );
		final y = a * math.sin( t );
		final z = 2 * a * math.sin( t / 2 );

		return point.setValues( x, y, z );
	}
}

// KnotCurve

class KnotCurve extends Curve {

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		t *= 2 * math.pi;

		const R = 10;
		const s = 50;

		final x = s * math.sin( t );
		final y = math.cos( t ) * ( R + s * math.cos( t ) );
		final z = math.sin( t ) * ( R + s * math.cos( t ) );

		return point.setValues( x, y, z );
	}
}


// HelixCurve

class HelixCurve extends Curve {

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		const a = 30; // radius
		const b = 150; // height

		final t2 = 2 * math.pi * t * b / 30;

		final x = math.cos( t2 ) * a;
		final y = math.sin( t2 ) * a;
		final z = b * t;

		return point.setValues( x, y, z );
	}
}

// TrefoilKnot

class TrefoilKnot extends Curve {
  double scale;
	TrefoilKnot([this.scale = 10 ]):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		t *= math.pi * 2;

		final x = ( 2 + math.cos( 3 * t ) ) * math.cos( 2 * t );
		final y = ( 2 + math.cos( 3 * t ) ) * math.sin( 2 * t );
		final z = math.sin( 3 * t );

		return point.setValues( x, y, z ).scale( scale );

	}

}

// TorusKnot

class TorusKnot extends Curve {
  double scale;
	TorusKnot([this.scale = 10 ]):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		const p = 3;
		const q = 4;

		t *= math.pi * 2;

		final x = ( 2 + math.cos( q * t ) ) * math.cos( p * t );
		final y = ( 2 + math.cos( q * t ) ) * math.sin( p * t );
		final z = math.sin( q * t );

		return point.setValues( x, y, z ).scale(scale );
	}
}

// CinquefoilKnot

class CinquefoilKnot extends Curve {
  double scale;
	CinquefoilKnot([ this.scale = 10 ]):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		const p = 2;
		const q = 5;

		t *= math.pi * 2;

		final x = ( 2 + math.cos( q * t ) ) * math.cos( p * t );
		final y = ( 2 + math.cos( q * t ) ) * math.sin( p * t );
		final z = math.sin( q * t );

		return point.setValues( x, y, z ).scale(scale );
	}
}


// TrefoilPolynomialKnot

class TrefoilPolynomialKnot extends Curve {
  double scale;
	TrefoilPolynomialKnot([ this.scale = 10 ]):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		t = t * 4 - 2;

		final x = math.pow( t, 3 ) - 3 * t;
		final y = math.pow( t, 4 ) - 4 * t * t;
		final z = 1 / 5 * math.pow( t, 5 ) - 2 * t;

		return point.setValues( x, y, z ).scale( scale );
	}
}

double scaleTo(double x, double y, double t ) {
	final r = y - x;
	return t * r + x;
}

// FigureEightPolynomialKnot

class FigureEightPolynomialKnot extends Curve {
  double scale;
	FigureEightPolynomialKnot( [this.scale = 1 ]):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		t = scaleTo( - 4, 4, t );

		final x = 2 / 5 * t * ( t * t - 7 ) * ( t * t - 10 );
		final y = math.pow( t, 4 ) - 13 * t * t;
		final z = 1 / 10 * t * ( t * t - 4 ) * ( t * t - 9 ) * ( t * t - 12 );

		return point.setValues( x, y, z ).scale( scale );
	}
}

// DecoratedTorusKnot4a

class DecoratedTorusKnot4a extends Curve {
  double scale;
	DecoratedTorusKnot4a( [this.scale = 40] ):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		t *= math.pi * 2;

		final x = math.cos( 2 * t ) * ( 1 + 0.6 * ( math.cos( 5 * t ) + 0.75 * math.cos( 10 * t ) ) );
		final y = math.sin( 2 * t ) * ( 1 + 0.6 * ( math.cos( 5 * t ) + 0.75 * math.cos( 10 * t ) ) );
		final z = 0.35 * math.sin( 5 * t );

		return point.setValues( x, y, z ).scale( scale );
	}
}

// DecoratedTorusKnot4b

class DecoratedTorusKnot4b extends Curve {
  double scale;
	DecoratedTorusKnot4b( [this.scale = 40] ):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		final fi = t * math.pi * 2;

		final x = math.cos( 2 * fi ) * ( 1 + 0.45 * math.cos( 3 * fi ) + 0.4 * math.cos( 9 * fi ) );
		final y = math.sin( 2 * fi ) * ( 1 + 0.45 * math.cos( 3 * fi ) + 0.4 * math.cos( 9 * fi ) );
		final z = 0.2 * math.sin( 9 * fi );

		return point.setValues( x, y, z ).scale( scale );
	}
}


// DecoratedTorusKnot5a

class DecoratedTorusKnot5a extends Curve {
  double scale;
	DecoratedTorusKnot5a( [this.scale = 40] ):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		final fi = t * math.pi * 2;

		final x = math.cos( 3 * fi ) * ( 1 + 0.3 * math.cos( 5 * fi ) + 0.5 * math.cos( 10 * fi ) );
		final y = math.sin( 3 * fi ) * ( 1 + 0.3 * math.cos( 5 * fi ) + 0.5 * math.cos( 10 * fi ) );
		final z = 0.2 * math.sin( 20 * fi );

		return point.setValues( x, y, z ).scale( scale );
	}
}

// DecoratedTorusKnot5c

class DecoratedTorusKnot5c extends Curve {
  double scale;
	DecoratedTorusKnot5c( [this.scale = 40] ):super();

	@override
	Vector? getPoint(double t, [Vector? optionalTarget]) {
    optionalTarget ??= Vector3();
    late Vector3 optTarget;

    if(optionalTarget is Vector2){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,0);
    }
    else if(optionalTarget is Vector4){
      optTarget = Vector3(optionalTarget.x,optionalTarget.y,optionalTarget.z);
    }
    else{
      optTarget = optionalTarget as Vector3;
    }

		final point = optTarget;

		final fi = t * math.pi * 2;

		final x = math.cos( 4 * fi ) * ( 1 + 0.5 * ( math.cos( 5 * fi ) + 0.4 * math.cos( 20 * fi ) ) );
		final y = math.sin( 4 * fi ) * ( 1 + 0.5 * ( math.cos( 5 * fi ) + 0.4 * math.cos( 20 * fi ) ) );
		final z = 0.35 * math.sin( 15 * fi );

		return point.setValues( x, y, z ).scale( scale );
	}
}