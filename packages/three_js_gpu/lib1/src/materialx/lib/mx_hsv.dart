import 'dart:math';

final mx_hsvtorgb = /*@__PURE__*/ Fn( ( [ hsv ] ) {

	final s = hsv.y;
	final v = hsv.z;

	final result = vec3().toVar();

	If( s.lessThan( 0.0001 ), () {

		result.assign( vec3( v, v, v ) );

	} ).Else( () {

		var h = hsv.x;
		h = h.sub( floor( h ) ).mul( 6.0 ).toVar(); // TODO: check what .toVar() is needed in node system cache
		final hi = int( trunc( h ) );
		final f = h.sub( float( hi ) );
		final p = v.mul( s.oneMinus() );
		final q = v.mul( s.mul( f ).oneMinus() );
		final t = v.mul( s.mul( f.oneMinus() ).oneMinus() );

		If( hi.equal( int( 0 ) ), () {

			result.assign( vec3( v, t, p ) );

		} ).ElseIf( hi.equal( int( 1 ) ), () {

			result.assign( vec3( q, v, p ) );

		} ).ElseIf( hi.equal( int( 2 ) ), () {

			result.assign( vec3( p, v, t ) );

		} ).ElseIf( hi.equal( int( 3 ) ), () {

			result.assign( vec3( p, q, v ) );

		} ).ElseIf( hi.equal( int( 4 ) ), () {

			result.assign( vec3( t, p, v ) );

		} ).Else( () {

			result.assign( vec3( v, p, q ) );

		} );

	} );

	return result;

} ).setLayout( {
	'name': 'mx_hsvtorgb',
	'type': 'vec3',
	'inputs': [
		{ 'name': 'hsv', 'type': 'vec3' }
	]
} );

final mx_rgbtohsv = /*@__PURE__*/ Fn( ( [ c_immutable ] ) {

	final c = vec3( c_immutable ).toVar();
	final r = float( c.x ).toVar();
	final g = float( c.y ).toVar();
	final b = float( c.z ).toVar();
	final mincomp = float( min( r, min( g, b ) ) ).toVar();
	final maxcomp = float( max( r, max( g, b ) ) ).toVar();
	final delta = float( maxcomp.sub( mincomp ) ).toVar();
	final h = float().toVar(), s = float().toVar(), v = float().toVar();
	v.assign( maxcomp );

	If( maxcomp.greaterThan( 0.0 ), () => {

		s.assign( delta.div( maxcomp ) );

	} ).Else( () => {

		s.assign( 0.0 );

	} );

	If( s.lessThanEqual( 0.0 ), () {

		h.assign( 0.0 );

	} ).Else( () {

		If( r.greaterThanEqual( maxcomp ), () {

			h.assign( g.sub( b ).div( delta ) );

		} ).ElseIf( g.greaterThanEqual( maxcomp ), () {

			h.assign( add( 2.0, b.sub( r ).div( delta ) ) );

		} ).Else( () {

			h.assign( add( 4.0, r.sub( g ).div( delta ) ) );

		} );

		h.mulAssign( 1.0 / 6.0 );

		If( h.lessThan( 0.0 ), () {

			h.addAssign( 1.0 );

		} );

	} );

	return vec3( h, s, v );

} ).setLayout( {
	'name': 'mx_rgbtohsv',
	'type': 'vec3',
	'inputs': [
		{ 'name': 'c', 'type': 'vec3' }
	]
} );
