import 'package:flutter/foundation.dart';

const luminosityShader = {
	'uniforms': {
		'tDiffuse': { 'value': null }
	},
	'vertexShader': /* glsl */'''

		varying vec2 vUv;

		void main() {

			vUv = uv;

			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}''',

	'fragmentShader': /* glsl */'''

		#include <common>

		uniform sampler2D tDiffuse;

		varying vec2 vUv;

		void main() {

			vec4 texel = texture2D( tDiffuse, vUv );

      const vec3 lumaCoeffs = vec3( 0.2125, 0.7154, 0.0721 );
			float l = dot( texel.rgb, lumaCoeffs ) * ${kIsWeb?'1.0':'0.1'};//luminance( texel.rgb );

			gl_FragColor = vec4( l, l, l, texel.w );

		}'''//
};
