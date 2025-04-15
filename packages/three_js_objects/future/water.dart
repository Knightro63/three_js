import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * Work based on :
 * https://github.com/Slayvin: Flat mirror for three.js
 * https://home.adelphi.edu/~stemkoski/ : An implementation of water shader based on the flat mirror
 * http://29a.ch/ && http://29a.ch/slides/2012/webglwater/ : Water shader explanations in WebGL
 */

class WaterOld extends Mesh {

	WaterOld(super.geometry, [Map<String,dynamic>? options] ) {
    options ??= {};

		final textureWidth = options['textureWidth'] ?? 512;
		final textureHeight = options['textureHeight'] ?? 512;

		final clipBias = options['clipBias'] ?? 0.0;
		final alpha = options['alpha'] ?? 1.0;
		final time = options['time'] ?? 0.0;
		final normalSampler = options['waterNormals'];
		final sunDirection = options['sunDirection'] ?? Vector3( 0.70707, 0.70707, 0.0 );
		final sunColor = Color.fromHex32(options['sunColor'] ?? 0xffffff);
		final waterColor = Color.fromHex32(options['waterColor'] ?? 0x7F7F7F );
		final eye = options['eye'] ?? Vector3();
		final distortionScale = options['distortionScale'] ?? 8.0;
		final side = options['side'] ?? FrontSide;
		final fog = options['fog'] ?? false;

		//
		final mirrorPlane = Plane();
		final normal = Vector3();
		final mirrorWorldPosition = Vector3();
		final cameraWorldPosition = Vector3();
		final rotationMatrix = Matrix4.identity();
		final lookAtPosition = Vector3( 0, 0, - 1 );
		final clipPlane = Vector4.identity();

		final view = Vector3();
		final target = Vector3();
		final q = Vector4.identity();

		final textureMatrix = Matrix4.identity();

		final mirrorCamera = PerspectiveCamera();

		final rt = WebGLRenderTarget( textureWidth, textureHeight );

		final Map<String,dynamic> mirrorShader = {
      'name': 'MirrorShader',
			'uniforms': UniformsUtils.merge( [
				//uniformsLib[ 'fog' ],
				uniformsLib[ 'lights' ],
				{
					'normalSampler': { 'value': null },
					'mirrorSampler': { 'value': null },
					'alpha': { 'value': 1.0 },
					'time': { 'value': 1.0 },
					'size': { 'value': 1.0 },
					'distortionScale': { 'value': 20.0 },
					'textureMatrix': { 'value': Matrix4.identity() },
					'sunColor': { 'value': Color.fromHex32(0x7f7f7f) },
					'sunDirection': { 'value': Vector3( 0.70707, 0.70707, 0 ) },
					'eye': { 'value': Vector3() },
					'waterColor': { 'value': Color.fromHex32( 0x555555 ) }
				}
			] ),

			'vertexShader': /* glsl */'''
				uniform mat4 textureMatrix;
				uniform float time;

				varying vec4 mirrorCoord;
				varying vec4 worldPosition;

				#include <common>
				#include <fog_pars_vertex>
				#include <shadowmap_pars_vertex>
				#include <logdepthbuf_pars_vertex>

				void main() {
					mirrorCoord = modelMatrix * vec4( position, 1.0 );
					worldPosition = mirrorCoord.xyzw;
					mirrorCoord = textureMatrix * mirrorCoord;
					vec4 mvPosition =  modelViewMatrix * vec4( position, 1.0 );
					gl_Position = projectionMatrix * mvPosition;

				#include <beginnormal_vertex>
				#include <defaultnormal_vertex>
				#include <logdepthbuf_vertex>
				#include <fog_vertex>
				#include <shadowmap_vertex>
			}''',

			'fragmentShader': /* glsl */'''
				uniform sampler2D mirrorSampler;
				uniform float alpha;
				uniform float time;
				uniform float size;
				uniform float distortionScale;
				uniform sampler2D normalSampler;
				uniform vec3 sunColor;
				uniform vec3 sunDirection;
				uniform vec3 eye;
				uniform vec3 waterColor;

				varying vec4 mirrorCoord;
				varying vec4 worldPosition;

				vec4 getNoise( vec2 uv ) {
					vec2 uv0 = ( uv / 103.0 ) + vec2(time / 17.0, time / 29.0);
					vec2 uv1 = uv / 107.0-vec2( time / -19.0, time / 31.0 );
					vec2 uv2 = uv / vec2( 8907.0, 9803.0 ) + vec2( time / 101.0, time / 97.0 );
					vec2 uv3 = uv / vec2( 1091.0, 1027.0 ) - vec2( time / 109.0, time / -113.0 );
					vec4 noise = texture2D( normalSampler, uv0 ) +
						texture2D( normalSampler, uv1 ) +
						texture2D( normalSampler, uv2 ) +
						texture2D( normalSampler, uv3 );
					return noise * 0.5 - 1.0;
				}

				void sunLight( const vec3 surfaceNormal, const vec3 eyeDirection, float shiny, float spec, float diffuse, inout vec3 diffuseColor, inout vec3 specularColor ) {
					vec3 reflection = normalize( reflect( -sunDirection, surfaceNormal ) );
					float direction = max( 0.0, dot( eyeDirection, reflection ) );
					specularColor += pow( direction, shiny ) * sunColor * spec;
					diffuseColor += max( dot( sunDirection, surfaceNormal ), 0.0 ) * sunColor * diffuse;
				}

				#include <common>
				#include <packing>
				#include <bsdfs>
				#include <fog_pars_fragment>
				#include <logdepthbuf_pars_fragment>
				#include <lights_pars_begin>
				#include <shadowmap_pars_fragment>
				#include <shadowmask_pars_fragment>

				void main() {

					#include <logdepthbuf_fragment>
					vec4 noise = getNoise( worldPosition.xz * size );
					vec3 surfaceNormal = normalize( noise.xzy * vec3( 1.5, 1.0, 1.5 ) );

					vec3 diffuseLight = vec3(0.0);
					vec3 specularLight = vec3(0.0);

					vec3 worldToEye = eye-worldPosition.xyz;
					vec3 eyeDirection = normalize( worldToEye );
					sunLight( surfaceNormal, eyeDirection, 100.0, 2.0, 0.5, diffuseLight, specularLight );

					float distance = length(worldToEye);

					vec2 distortion = surfaceNormal.xz * ( 0.001 + 1.0 / distance ) * distortionScale;
					vec3 reflectionSample = vec3( texture2D( mirrorSampler, mirrorCoord.xy / mirrorCoord.w + distortion ) );

					float theta = max( dot( eyeDirection, surfaceNormal ), 0.0 );
					float rf0 = 0.3;
					float reflectance = rf0 + ( 1.0 - rf0 ) * pow( ( 1.0 - theta ), 5.0 );
					vec3 scatter = max( 0.0, dot( surfaceNormal, eyeDirection ) ) * waterColor;
					vec3 albedo = mix( ( sunColor * diffuseLight * 0.3 + scatter ) * getShadowMask(), ( vec3( 0.1 ) + reflectionSample * 0.9 + reflectionSample * specularLight ), reflectance);
					vec3 outgoingLight = albedo;
					gl_FragColor = vec4( outgoingLight, alpha );

					#include <tonemapping_fragment>
					#include <colorspace_fragment>
					#include <fog_fragment>	
				}'''

		};

		final material = ShaderMaterial.fromMap( {
      'name': mirrorShader['name'],
			'fragmentShader': mirrorShader['fragmentShader'],
			'vertexShader': mirrorShader['vertexShader'],
			'uniforms': UniformsUtils.clone( mirrorShader['uniforms'] ),
			'lights': true,
			'side': side,
			'fog': fog
		} );

		material.uniforms[ 'mirrorSampler' ]['value'] = rt.texture;
		material.uniforms[ 'textureMatrix' ]['value'] = textureMatrix;
		material.uniforms[ 'alpha' ]['value'] = alpha;
		material.uniforms[ 'time' ]['value'] = time;
		material.uniforms[ 'normalSampler' ]['value'] = normalSampler;
		material.uniforms[ 'sunColor' ]['value'] = sunColor;
		material.uniforms[ 'waterColor' ]['value'] = waterColor;
		material.uniforms[ 'sunDirection' ]['value'] = sunDirection;
		material.uniforms[ 'distortionScale' ]['value'] = distortionScale;

		material.uniforms[ 'eye' ]['value'] = eye;

		this.material = material;

    onAfterRender = ({Camera? camera, BufferGeometry? geometry, Map<String, dynamic>? group, Material? material, WebGLRenderer? renderer, Object3D? scene}){

			mirrorWorldPosition.setFromMatrixPosition( this.matrixWorld );
			cameraWorldPosition.setFromMatrixPosition( camera!.matrixWorld );

			rotationMatrix.extractRotation( this.matrixWorld );

			normal.setValues( 0, 0, 1 );
			normal.applyMatrix4( rotationMatrix );

			view.sub2( mirrorWorldPosition, cameraWorldPosition );

			// Avoid rendering when mirror is facing away

			if ( view.dot( normal ) > 0 ) return;

			view.reflect( normal ).negate();
			view.add( mirrorWorldPosition );

			rotationMatrix.extractRotation( camera.matrixWorld );

			lookAtPosition.setValues( 0, 0, - 1 );
			lookAtPosition.applyMatrix4( rotationMatrix );
			lookAtPosition.add( cameraWorldPosition );

			target.sub2( mirrorWorldPosition, lookAtPosition );
			target.reflect( normal ).negate();
			target.add( mirrorWorldPosition );

			mirrorCamera.position.setFrom( view );
			mirrorCamera.up.setValues( 0, 1, 0 );
			mirrorCamera.up.applyMatrix4( rotationMatrix );
			mirrorCamera.up.reflect( normal );
			mirrorCamera.lookAt( target );

			mirrorCamera.far = camera.far; // Used in WebGLBackground

			mirrorCamera.updateMatrixWorld();
			mirrorCamera.projectionMatrix.setFrom( camera.projectionMatrix );

			// Update the texture matrix
			textureMatrix.setValues(
				0.5, 0.0, 0.0, 0.5,
				0.0, 0.5, 0.0, 0.5,
				0.0, 0.0, 0.5, 0.5,
				0.0, 0.0, 0.0, 1.0
			);
			textureMatrix.multiply( mirrorCamera.projectionMatrix );
			textureMatrix.multiply( mirrorCamera.matrixWorldInverse );

			// Now update projection matrix with clip plane, implementing code from: http://www.terathon.com/code/oblique.html
			// Paper explaining this technique: http://www.terathon.com/lengyel/Lengyel-Oblique.pdf
			mirrorPlane.setFromNormalAndCoplanarPoint( normal, mirrorWorldPosition );
			mirrorPlane.applyMatrix4( mirrorCamera.matrixWorldInverse );

			clipPlane.setValues( mirrorPlane.normal.x, mirrorPlane.normal.y, mirrorPlane.normal.z, mirrorPlane.constant );

			final projectionMatrix = mirrorCamera.projectionMatrix;

			q.x = ( clipPlane.x.sign + projectionMatrix.storage[ 8 ] ) / projectionMatrix.storage[ 0 ];
			q.y = ( clipPlane.y.sign + projectionMatrix.storage[ 9 ] ) / projectionMatrix.storage[ 5 ];
			q.z = - 1.0;
			q.w = ( 1.0 + projectionMatrix.storage[ 10 ] ) / projectionMatrix.storage[ 14 ];

			// Calculate the scaled plane vector
			clipPlane.scale( 2.0 / clipPlane.dot( q ) );

			// Replacing the third row of the projection matrix
			projectionMatrix.storage[ 2 ] = clipPlane.x;
			projectionMatrix.storage[ 6 ] = clipPlane.y;
			projectionMatrix.storage[ 10 ] = clipPlane.z + 1.0 - clipBias;
			projectionMatrix.storage[ 14 ] = clipPlane.w;

			eye.setFromMatrixPosition( camera.matrixWorld );

			// Render

			final currentRenderTarget = renderer!.getRenderTarget();

			final currentXrEnabled = renderer.xr.enabled;
			final currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

			this.visible = false;

			renderer.xr.enabled = false; // Avoid camera modification and recursion
			renderer.shadowMap.autoUpdate = false; // Avoid re-computing shadows

			renderer.setRenderTarget( rt );

			renderer.state.buffers['depth'].setMask( true ); // make sure the depth buffer is writable so it can be properly cleared, see #18897

			if ( renderer.autoClear == false ) renderer.clear();
			renderer.render( scene!, mirrorCamera );

			this.visible = true;

			renderer.xr.enabled = currentXrEnabled;
			renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;

			renderer.setRenderTarget( currentRenderTarget );

			// Restore viewport

			final viewport = camera.viewport;

			if ( viewport != null ) {
			  renderer.state.viewport( viewport );
			}
		};
	}
}
