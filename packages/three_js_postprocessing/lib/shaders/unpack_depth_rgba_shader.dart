/**
 * Unpack RGBA depth shader
 * - show RGBA encoded depth as monochrome color
 */

final Map<String, dynamic> unpackDepthRGBAShader = {
  "uniforms": {
    'tDiffuse': {},
    'opacity': {"value": 1.0}
  },
  "vertexShader": """

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}
  """,
  "fragmentShader": """

		uniform float opacity;

		uniform sampler2D tDiffuse;

		varying vec2 vUv;

		#include <packing>

		void main() {

			float depth = 1.0 - unpackRGBAToDepth( texture2D( tDiffuse, vUv ) );
			gl_FragColor = vec4( vec3( depth ), opacity );

		}
  """
};
