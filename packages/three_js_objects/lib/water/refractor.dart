import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'reflector.dart';

class Refractor extends Mesh {
  final bool isRefractor = true;
  late WebGLRenderTarget renderTarget;
  PerspectiveCamera camera = PerspectiveCamera();

	Refractor(super.geometry, [Map<String,dynamic>? options] ) {
		type = 'Refractor';
    options ??= {};

		final scope = this;

		final color = Color.fromHex32( options['color'] ?? 0x7F7F7F);
		final textureWidth = options['textureWidth'] ?? 512;
		final textureHeight = options['textureHeight'] ?? 512;
		final clipBias = options['clipBias'] ?? 0;
		final shader = options['shader'] ?? Reflector.reflectorShader;
		final multisample = options['multisample'] ?? 4;
		//

		final virtualCamera = camera;
		virtualCamera.matrixAutoUpdate = false;
		virtualCamera.userData['refractor'] = true;

		final refractorPlane = Plane();
		final textureMatrix = Matrix4();

		// render target

		renderTarget = WebGLRenderTarget( textureWidth, textureHeight, WebGLRenderTargetOptions({'samples': multisample, 'type': HalfFloatType}));

		// material

		material = ShaderMaterial.fromMap( {
			'uniforms': UniformsUtils.clone( shader['uniforms'] ),
			'vertexShader': shader['vertexShader'],
			'fragmentShader': shader['fragmentShader'],
			'transparent': true // ensures, refractors are drawn from farthest to closest
		} );

		material?.uniforms[ 'color' ]['value'] = color;
		material?.uniforms[ 'tDiffuse' ]['value'] = renderTarget.texture;
		material?.uniforms[ 'textureMatrix' ]['value'] = textureMatrix;

		// functions

		final visible = (() {

			final refractorWorldPosition = Vector3();
			final cameraWorldPosition = Vector3();
			final rotationMatrix = Matrix4();

			final view = Vector3();
			final normal = Vector3();

			return ( camera ) {

				refractorWorldPosition.setFromMatrixPosition( scope.matrixWorld );
				cameraWorldPosition.setFromMatrixPosition( camera.matrixWorld );

				view.sub2( refractorWorldPosition, cameraWorldPosition );

				rotationMatrix.extractRotation( scope.matrixWorld );

				normal.setValues( 0, 0, 1 );
				normal.applyMatrix4( rotationMatrix );

				return view.dot( normal ) < 0;

			};

		})();

		final updateRefractorPlane = (() {

			final normal = Vector3();
			final position = Vector3();
			final quaternion = Quaternion();
			final scale = Vector3();

			return() {

				scope.matrixWorld.decompose( position, quaternion, scale );
				normal.setValues( 0, 0, 1 ).applyQuaternion( quaternion ).normalize();

				// flip the normal because we want to cull everything above the plane

				normal.negate();

				refractorPlane.setFromNormalAndCoplanarPoint( normal, position );

			};

		})();

		final updateVirtualCamera = (() {

			final clipPlane = Plane();
			final clipVector = Vector4();
			final q = Vector4();

			return (Camera camera ) {

				virtualCamera.matrixWorld.setFrom( camera.matrixWorld );
				virtualCamera.matrixWorldInverse.setFrom( virtualCamera.matrixWorld ).invert();
				virtualCamera.projectionMatrix.setFrom( camera.projectionMatrix );
				virtualCamera.far = camera.far; // used in WebGLBackground

				// The following code creates an oblique view frustum for clipping.
				// see: Lengyel, Eric. “Oblique View Frustum Depth Projection and Clipping”.
				// Journal of Game Development, Vol. 1, No. 2 (2005), Charles River Media, pp. 5–16

				clipPlane.copyFrom( refractorPlane );
				clipPlane.applyMatrix4( virtualCamera.matrixWorldInverse );

				clipVector.setValues( clipPlane.normal.x, clipPlane.normal.y, clipPlane.normal.z, clipPlane.constant );

				// calculate the clip-space corner point opposite the clipping plane and
				// transform it into camera space by multiplying it by the inverse of the projection matrix

				final projectionMatrix = virtualCamera.projectionMatrix;

				q.x = (clipVector.x.sign + projectionMatrix.storage[ 8 ] ) / projectionMatrix.storage[ 0 ];
				q.y = (clipVector.y.sign + projectionMatrix.storage[ 9 ] ) / projectionMatrix.storage[ 5 ];
				q.z = - 1.0;
				q.w = ( 1.0 + projectionMatrix.storage[ 10 ] ) / projectionMatrix.storage[ 14 ];

				// calculate the scaled plane vector

				clipVector.scale( 2.0 / clipVector.dot( q ) );

				// replacing the third row of the projection matrix

				projectionMatrix.storage[ 2 ] = clipVector.x;
				projectionMatrix.storage[ 6 ] = clipVector.y;
				projectionMatrix.storage[ 10 ] = clipVector.z + 1.0 - clipBias;
				projectionMatrix.storage[ 14 ] = clipVector.w;

			};

		} )();

		// This will update the texture matrix that is used for projective texture mapping in the shader.
		// see: http://developer.download.nvidia.com/assets/gamedev/docs/projective_texture_mapping.pdf

		void updateTextureMatrix(Camera camera ) {
			// this matrix does range mapping to [ 0, 1 ]

			textureMatrix.setValues(
				0.5, 0.0, 0.0, 0.5,
				0.0, 0.5, 0.0, 0.5,
				0.0, 0.0, 0.5, 0.5,
				0.0, 0.0, 0.0, 1.0
			);

			// we use "Object Linear Texgen", so we need to multiply the texture matrix T
			// (matrix above) with the projection and view matrix of the virtual camera
			// and the model matrix of the refractor

			textureMatrix.multiply( camera.projectionMatrix );
			textureMatrix.multiply( camera.matrixWorldInverse );
			textureMatrix.multiply( scope.matrixWorld );
		}

		//

		void render(WebGLRenderer renderer, Object3D scene, Camera camera ) {

			scope.visible = false;

			final currentRenderTarget = renderer.getRenderTarget();
			final currentXrEnabled = renderer.xr.enabled;
			final currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

			renderer.xr.enabled = false; // avoid camera modification
			renderer.shadowMap.autoUpdate = false; // avoid re-computing shadows

			renderer.setRenderTarget( renderTarget );
			if ( renderer.autoClear == false ) renderer.clear();
			renderer.render( scene, virtualCamera );

			renderer.xr.enabled = currentXrEnabled;
			renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;
			renderer.setRenderTarget( currentRenderTarget );

			// restore viewport

			final viewport = camera.viewport;

			if ( viewport != null ) {
				renderer.state.viewport( viewport );
			}

			scope.visible = true;
		}

		//

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

			// ensure refractors are rendered only once per frame

			if ( camera?.userData['refractor'] == true ) return;
			// avoid rendering when the refractor is viewed from behind
			if ( !visible( camera ) == true ) return;

			// update

			updateRefractorPlane();
			updateTextureMatrix( camera! );
			updateVirtualCamera( camera );
			render( renderer!, scene!, camera );
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

  static Map<String,dynamic> refractorShader = {
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

      void main() {

        vUv = textureMatrix * vec4( position, 1.0 );
        gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

      }''',

    'fragmentShader': /* glsl */'''

      uniform vec3 color;
      uniform sampler2D tDiffuse;

      varying vec4 vUv;

      float blendOverlay( float base, float blend ) {

        return( base < 0.5 ? ( 2.0 * base * blend ) : ( 1.0 - 2.0 * ( 1.0 - base ) * ( 1.0 - blend ) ) );

      }

      vec3 blendOverlay( vec3 base, vec3 blend ) {

        return vec3( blendOverlay( base.r, blend.r ), blendOverlay( base.g, blend.g ), blendOverlay( base.b, blend.b ) );

      }

      void main() {

        vec4 base = texture2DProj( tDiffuse, vUv );
        gl_FragColor = vec4( blendOverlay( base.rgb, color ), 1.0 );

        #include <tonemapping_fragment>
        #include <colorspace_fragment>

      }'''

  };

}