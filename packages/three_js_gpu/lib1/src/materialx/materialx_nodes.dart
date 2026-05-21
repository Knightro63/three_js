

mx_aastep( threshold, value ){
	threshold = double.parse( threshold );
	value = double.parse( value );
	const afwidth = vec2( value.dFdx(), value.dFdy() ).length().mul( 0.70710678118654757 );
	return smoothstep( threshold.sub( afwidth ), threshold.add( afwidth ), value );
}

mx_ramplr( valuel, valuer, [texcoord = uv() ]){
	return mix( valuel, valuer, texcoord.x.clamp() );
}
mx_ramptb( valuet, valueb, [texcoord = uv() ]){
	return mix( valuet, valueb, texcoord.y.clamp() );
}

mx_splitlr( valuel, valuer, center, [texcoord = uv() ]){
	return mix( valuel, valuer, mx_aastep( center, texcoord.x ) );
}
mx_splittb( valuet, valueb, center, [texcoord = uv() ]){
	return mix( valuet, valueb, mx_aastep( center, texcoord.y ) );
}

mx_transform_uv([ uv_scale = 1, uv_offset = 0, uv_geo = uv() ]){
	return uv_geo.mul( uv_scale ).add( uv_offset );
}

mx_safepower( in1, [in2 = 1 ]){
	in1 = double.parse( in1 );
	return in1.abs().pow( in2 ).mul( in1.sign() );
}
mx_contrast( input, [amount = 1, pivot = .5 ]){
	input = double.parse( input );
	return input.sub( pivot ).mul( amount ).add( pivot );
}

mx_noise_float([ texcoord = uv(), amplitude = 1, pivot = 0 ]){
	return mx_perlin_noise_float( texcoord.convert( 'vec2|vec3' ) ).mul( amplitude ).add( pivot );
}
//export const mx_noise_vec2 = ( texcoord = uv(), amplitude = 1, pivot = 0 ) => mx_perlin_noise_vec3( texcoord.convert( 'vec2|vec3' ) ).mul( amplitude ).add( pivot );
mx_noise_vec3([ texcoord = uv(), amplitude = 1, pivot = 0 ]){
	return mx_perlin_noise_vec3( texcoord.convert( 'vec2|vec3' ) ).mul( amplitude ).add( pivot );
}
mx_noise_vec4([ texcoord = uv(), amplitude = 1, pivot = 0 ]){

	texcoord = texcoord.convert( 'vec2|vec3' ); // overloading type

	const noise_vec4 = vec4( mx_perlin_noise_vec3( texcoord ), mx_perlin_noise_float( texcoord.add( vec2( 19, 73 ) ) ) );

	return noise_vec4.mul( amplitude ).add( pivot );

}

mx_worley_noise_float([ texcoord = uv(), jitter = 1 ]){
	return worley_noise_float( texcoord.convert( 'vec2|vec3' ), jitter, 1);
}
mx_worley_noise_vec2([ texcoord = uv(), jitter = 1 ]){
	return worley_noise_vec2( texcoord.convert( 'vec2|vec3' ), jitter, 1 );
}
mx_worley_noise_vec3([ texcoord = uv(), jitter = 1 ]){
	return worley_noise_vec3( texcoord.convert( 'vec2|vec3' ), jitter, 1 );
}

mx_cell_noise_float([ texcoord = uv() ]){
	return cell_noise_float( texcoord.convert( 'vec2|vec3' ) );
}

mx_fractal_noise_float([ position = uv(), octaves = 3, lacunarity = 2, diminish = .5, amplitude = 1 ]){
	return fractal_noise_float( position, octaves, lacunarity, diminish ).mul( amplitude );
}
mx_fractal_noise_vec2([ position = uv(), octaves = 3, lacunarity = 2, diminish = .5, amplitude = 1 ]){
	return fractal_noise_vec2( position, octaves, lacunarity, diminish ).mul( amplitude );
}
mx_fractal_noise_vec3([ position = uv(), octaves = 3, lacunarity = 2, diminish = .5, amplitude = 1 ]){
	return fractal_noise_vec3( position, octaves, lacunarity, diminish ).mul( amplitude );
}
mx_fractal_noise_vec4([ position = uv(), octaves = 3, lacunarity = 2, diminish = .5, amplitude = 1 ]){
	return fractal_noise_vec4( position, octaves, lacunarity, diminish ).mul( amplitude );
}
