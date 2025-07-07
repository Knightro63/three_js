import 'package:three_js_core/three_js_core.dart';
import '../../app/web/xr_webgl_bindings.dart';

const occlusionVertex = '''
void main() {

	gl_Position = vec4( position, 1.0 );

}''';

const occlusionFragment = '''
uniform sampler2DArray depthColor;
uniform float depthWidth;
uniform float depthHeight;

void main() {

	vec2 coord = vec2( gl_FragCoord.x / depthWidth, gl_FragCoord.y / depthHeight );

	if ( coord.x >= 1.0 ) {

		gl_FragDepth = texture( depthColor, vec3( coord.x - 1.0, coord.y, 1 ) ).r;

	} else {

		gl_FragDepth = texture( depthColor, vec3( coord.x, coord.y, 0 ) ).r;

	}

}''';

class WebXRDepthSensing {

  Mesh? mesh;
  Texture? texture;
  double depthNear = 0;
  double depthFar = 0;

	WebXRDepthSensing();

	void init(WebGLRenderer renderer, XRWebGLDepthInformation depthData, XRRenderState renderState ) {
		if (texture == null ) {
			final texture = Texture();

			final texProps = renderer.properties.get( texture );
			texProps['__webglTexture'] = depthData.texture;

			if ( ( depthData.depthNear != renderState.depthNear ) || ( depthData.depthFar != renderState.depthFar ) ) {
				depthNear = depthData.depthNear;
				depthFar = depthData.depthFar;
			}

			this.texture = texture;
		}
	}

	void render(WebGLRenderer renderer, cameraXR ) {
		if ( texture != null ) {
			if ( mesh == null ) {
				final viewport = cameraXR.cameras[ 0 ].viewport;
				final material = ShaderMaterial.fromMap( {
					'vertexShader': occlusionVertex,
					'fragmentShader': occlusionFragment,
					'uniforms': {
						'depthColor': { 'value': texture },
						'depthWidth': { 'value': viewport.z },
						'depthHeight': { 'value': viewport.w }
					}
				} );

				mesh = Mesh(PlaneGeometry( 20, 20 ), material );
			}

			renderer.render(mesh!, cameraXR );
		}
	}

	Mesh? getMesh(ArrayCamera cameraXR ) {
		if ( texture != null ) {
			if ( mesh == null ) {
				final viewport = cameraXR.cameras[ 0 ].viewport;
				final material = ShaderMaterial.fromMap( {
					'vertexShader': occlusionVertex,
					'fragmentShader': occlusionFragment,
					'uniforms': {
						'depthColor': { 'value': texture },
						'depthWidth': { 'value': viewport?.z },
						'depthHeight': { 'value': viewport?.w }
					}
				} );

				mesh = Mesh(PlaneGeometry( 20, 20 ), material);
			}
		}

		return mesh;
	}


	void reset() {
	  texture = null;
		mesh = null;
	}
}
