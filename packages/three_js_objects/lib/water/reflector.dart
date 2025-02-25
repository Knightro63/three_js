import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class Reflector extends Mesh {
  final bool isReflector = true;
  late WebGLRenderTarget renderTarget;
  PerspectiveCamera camera = PerspectiveCamera();

	Reflector(super.geometry, [Map<String,dynamic>? options] ) {
    options ??= {};
		type = 'Reflector';

		final scope = this;

		final color = Color.fromHex32( options['color'] ?? 0x7F7F7F);
		final textureWidth = options['textureWidth'] ?? 512;
		final textureHeight = options['textureHeight'] ?? 512;
		final clipBias = options['clipBias'] ?? 0;
		final shader = options['shader'] ?? Reflector.reflectorShader;
		final multisample = options['multisample'] ?? 4;

		final reflectorPlane = Plane();
		final normal = Vector3();
		final reflectorWorldPosition = Vector3();
		final cameraWorldPosition = Vector3();
		final rotationMatrix = Matrix4();
		final lookAtPosition = Vector3( 0, 0, - 1 );
		final clipPlane = Vector4();

		final view = Vector3();
		final target = Vector3();
		final q = Vector4();

		final textureMatrix = Matrix4();
		final PerspectiveCamera virtualCamera = camera;

	  renderTarget = WebGLRenderTarget( textureWidth, textureHeight, WebGLRenderTargetOptions({'samples': multisample, 'type': HalfFloatType }));

		final material =  ShaderMaterial.fromMap( {
			'name': shader['name'] ?? 'unspecified',
			'uniforms': UniformsUtils.clone( shader['uniforms'] ),
			'fragmentShader': shader['fragmentShader'],
			'vertexShader': shader['vertexShader']
		} );

		material.uniforms[ 'tDiffuse' ]['value'] = renderTarget.texture;
		material.uniforms[ 'color' ]['value'] = color;
		material.uniforms[ 'textureMatrix' ]['value'] = textureMatrix;

    this.material = material;

		onBeforeRender = ({
      WebGLRenderer? renderer,
      RenderTarget? renderTarget,
      Object3D? mesh,
      Scene? scene,
      Camera? camera,
      BufferGeometry? geometry,
      Material? material,
      Map<String, dynamic>? group
    }){
			reflectorWorldPosition.setFromMatrixPosition( scope.matrixWorld );
			cameraWorldPosition.setFromMatrixPosition( camera!.matrixWorld );

			rotationMatrix.extractRotation( scope.matrixWorld );

			normal.setValues( 0, 0, 1 );
			normal.applyMatrix4( rotationMatrix );

			view.sub2( reflectorWorldPosition, cameraWorldPosition );

			// Avoid rendering when reflector is facing away

			if ( view.dot( normal ) > 0 ) return;

			view.reflect( normal ).negate();
			view.add( reflectorWorldPosition );

			rotationMatrix.extractRotation( camera.matrixWorld );

			lookAtPosition.setValues( 0, 0, - 1 );
			lookAtPosition.applyMatrix4( rotationMatrix );
			lookAtPosition.add( cameraWorldPosition );

			target.sub2( reflectorWorldPosition, lookAtPosition );
			target.reflect( normal ).negate();
			target.add( reflectorWorldPosition );

			virtualCamera.position.setFrom( view );
			virtualCamera.up.setValues( 0, 1, 0 );
			virtualCamera.up.applyMatrix4( rotationMatrix );
			virtualCamera.up.reflect( normal );
			virtualCamera.lookAt( target );

			virtualCamera.far = camera.far; // Used in WebGLBackground

			virtualCamera.updateMatrixWorld();
			virtualCamera.projectionMatrix.setFrom( camera.projectionMatrix );

			// Update the texture matrix
			textureMatrix.setValues(
				0.5, 0.0, 0.0, 0.5,
				0.0, 0.5, 0.0, 0.5,
				0.0, 0.0, 0.5, 0.5,
				0.0, 0.0, 0.0, 1.0
			);
			textureMatrix.multiply( virtualCamera.projectionMatrix );
			textureMatrix.multiply( virtualCamera.matrixWorldInverse );
			textureMatrix.multiply( scope.matrixWorld );

			// Now update projection matrix with clip plane, implementing code from: http://www.terathon.com/code/oblique.html
			// Paper explaining this technique: http://www.terathon.com/lengyel/Lengyel-Oblique.pdf
			reflectorPlane.setFromNormalAndCoplanarPoint( normal, reflectorWorldPosition );
			reflectorPlane.applyMatrix4( virtualCamera.matrixWorldInverse );

			clipPlane.setValues( reflectorPlane.normal.x, reflectorPlane.normal.y, reflectorPlane.normal.z, reflectorPlane.constant );

			final projectionMatrix = virtualCamera.projectionMatrix;

			q.x = (clipPlane.x.sign + projectionMatrix.storage[ 8 ] ) / projectionMatrix.storage[ 0 ];
			q.y = (clipPlane.y.sign + projectionMatrix.storage[ 9 ] ) / projectionMatrix.storage[ 5 ];
			q.z = - 1.0;
			q.w = ( 1.0 + projectionMatrix.storage[ 10 ] ) / projectionMatrix.storage[ 14 ];

			// Calculate the scaled plane vector
			clipPlane.scale( 2.0 / clipPlane.dot( q ) );

			// Replacing the third row of the projection matrix
			projectionMatrix.storage[ 2 ] = clipPlane.x;
			projectionMatrix.storage[ 6 ] = clipPlane.y;
			projectionMatrix.storage[ 10 ] = clipPlane.z + 1.0 - clipBias;
			projectionMatrix.storage[ 14 ] = clipPlane.w;

			// Render
			scope.visible = false;

			final currentRenderTarget = renderer?.getRenderTarget();
			final currentXrEnabled = renderer?.xr.enabled;
			final currentShadowAutoUpdate = renderer?.shadowMap.autoUpdate;

			renderer?.xr.enabled = false; // Avoid camera modification
			renderer?.shadowMap.autoUpdate = false; // Avoid re-computing shadows

			renderer?.setRenderTarget( renderTarget );

			renderer?.state.buffers['depth'].setMask( true ); // make sure the depth buffer is writable so it can be properly cleared, see #18897

			if ( renderer?.autoClear == false ) renderer?.clear();
			renderer?.render( scene!, virtualCamera );

			renderer?.xr.enabled = currentXrEnabled!;
			renderer?.shadowMap.autoUpdate = currentShadowAutoUpdate!;

			renderer?.setRenderTarget( currentRenderTarget );

			// Restore viewport

			final viewport = camera.viewport;

			if ( viewport != null ) {
				renderer?.state.viewport( viewport );
			}

			scope.visible = true;
		};
	}

  WebGLRenderTarget getRenderTarget() {
    return renderTarget;
  }

  @override
  void dispose() {
    renderTarget.dispose();
    material?.dispose();
  }

  static Map<String,dynamic> reflectorShader = {

    'name': 'ReflectorShader',

    'uniforms': {

      'color': {
        'value': null
      },

      'tDiffuse': {
        'value': null
      },

      'textureMatrix': {
        'value': null
      }

    },

    'vertexShader': /* glsl */'''
      uniform mat4 textureMatrix;
      varying vec4 vUv;

      #include <common>
      #include <logdepthbuf_pars_vertex>

      void main() {
        vUv = textureMatrix * vec4( position, 1.0 );
        gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        #include <logdepthbuf_vertex>
      }''',

    'fragmentShader': /* glsl */'''
      uniform vec3 color;
      uniform sampler2D tDiffuse;
      varying vec4 vUv;

      #include <logdepthbuf_pars_fragment>

      float blendOverlay( float base, float blend ) {
        return( base < 0.5 ? ( 2.0 * base * blend ) : ( 1.0 - 2.0 * ( 1.0 - base ) * ( 1.0 - blend ) ) );
      }

      vec3 blendOverlay( vec3 base, vec3 blend ) {
        return vec3( blendOverlay( base.r, blend.r ), blendOverlay( base.g, blend.g ), blendOverlay( base.b, blend.b ) );
      }

      void main() {
        #include <logdepthbuf_fragment>

        vec4 base = texture2DProj( tDiffuse, vUv );
        gl_FragColor = vec4( blendOverlay( base.rgb, color ), 1.0 );

        #include <tonemapping_fragment>
        #include <colorspace_fragment>
      }'''
  };

}
