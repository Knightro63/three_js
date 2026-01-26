

final mx_srgb_texture_to_lin_rec709 = Fn( ( [ color_immutable ] ){

	final color = vec3( color_immutable ).toVar();
	final isAbove = bvec3( greaterThan( color, vec3( 0.04045 ) ) ).toVar();
	final linSeg = vec3( color.div( 12.92 ) ).toVar();
	final powSeg = vec3( pow( max( color.add( vec3( 0.055 ) ), vec3( 0.0 ) ).div( 1.055 ), vec3( 2.4 ) ) ).toVar();

	return mix( linSeg, powSeg, isAbove );

} ).setLayout( {
	'name': 'mx_srgb_texture_to_lin_rec709',
	'type': 'vec3',
	'inputs': [
		{ 'name': 'color', 'type': 'vec3' }
	]
} );
