import 'package:three_js_core/renderers/shaders/shader_chunk/index.dart';
import 'package:three_js_core/renderers/webgl/index.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_objects/csm/csm_shaders.dart';
import 'csm_frustum.dart';
import 'dart:math' as math;

enum CSMMode{practical,logarithmic,uniform,custom}

class CSMData{
  CSMData({
    required this.camera,
    required this.parent,
    this.cascades = 3,
    this.maxFar = 100000,
    this.mode = CSMMode.practical,
    this.shadowMapSize = 2048,
    this.shadowBias = 0.000001,
    Vector3? lightDirection,
    this.lightIntensity = 1,
    this.lightNear = 1,
    this.lightFar = 2000,
    this.lightMargin = 200,
    this.customSplitsCallback
  }){
    this.lightDirection = lightDirection ?? Vector3( 1, - 1, 1 ).normalize();
  }

  Camera camera;
  Scene parent;
  int cascades;
  double shadowMapSize;
  double shadowBias;
  double maxFar;
  double lightIntensity;
  double lightFar;
  double lightNear;
  double lightMargin;
  CSMMode mode;
  late Vector3 lightDirection;
  void Function(int amount,double near, double far, List<double> target)? customSplitsCallback;
}

class CSM{
  final _cameraToLightMatrix = Matrix4();
  final _lightSpaceFrustum = CSMFrustum();
  final _center = Vector3();
  final _bbox = BoundingBox();
  final List<double> _uniformArray = [];
  final List<double> _logArray = [];
  final _lightOrientationMatrix = Matrix4();
  final _lightOrientationMatrixInverse = Matrix4();
  final _up = Vector3( 0, 1, 0 );

  Map shaders = {};
  List<Light> lights = [];
  List<double> breaks = [];
  List<CSMFrustum> frustums = []; 
  CSMFrustum mainFrustum = CSMFrustum();
  bool fade = false;

  CSMData data;

	CSM(this.data){
		createLights();
		updateFrustums();
		injectInclude();
	}

	void createLights() {
		for ( int i = 0; i < data.cascades; i ++ ) {
			final light = DirectionalLight( 0xffffff, data.lightIntensity );
			light.castShadow = true;
			light.shadow?.mapSize.width = data.shadowMapSize;
			light.shadow?.mapSize.height = data.shadowMapSize;

			light.shadow?.camera?.near = data.lightNear;
			light.shadow?.camera?.far = data.lightFar;
			light.shadow?.bias = data.shadowBias;

			data.parent.add( light );
			data.parent.add( light.target );
			lights.add( light );
		}
	}

	void initCascades() {
		final camera = data.camera;
		camera.updateProjectionMatrix();
		mainFrustum.setFromProjectionMatrix( camera.projectionMatrix, data.maxFar );
		mainFrustum.split(breaks, frustums );
	}

	void updateShadowBounds() {
		final frustums = this.frustums;
		for (int i = 0; i < frustums.length; i ++ ) {

			final light = lights[ i ];
			final shadowCam = light.shadow?.camera;
			final frustum = this.frustums[ i ];

			// Get the two points that represent that furthest points on the frustum assuming
			// that's either the diagonal across the far plane or the diagonal across the whole
			// frustum itself.
			final nearVerts = frustum.vertices.near;
			final farVerts = frustum.vertices.far;
			final point1 = farVerts[ 0 ];
			late Vector3 point2;
			if ( point1.distanceTo( farVerts[ 2 ] ) > point1.distanceTo( nearVerts[ 2 ] ) ) {
				point2 = farVerts[ 2 ];
			} else {
				point2 = nearVerts[ 2 ];
			}

			double squaredBBWidth = point1.distanceTo( point2 );
			if ( fade ) {
				// expand the shadow extents by the fade margin if fade is enabled.
				final camera = data.camera;
				final far = math.max( camera.far, data.maxFar );
				final linearDepth = frustum.vertices.far[ 0 ].z / ( far - camera.near );
				final margin = 0.25 * math.pow( linearDepth, 2.0 ) * ( far - camera.near );
				squaredBBWidth += margin;
			}

			shadowCam?.left = - squaredBBWidth / 2;
			shadowCam?.right = squaredBBWidth / 2;
			shadowCam?.top = squaredBBWidth / 2;
			shadowCam?.bottom = - squaredBBWidth / 2;
			shadowCam?.updateProjectionMatrix();
		}
	}

		void uniformSplit(int amount, double near, double far,List<double>  target ) {
			for (int i = 1; i < amount; i ++ ) {
				target.add( ( near + ( far - near ) * i / amount ) / far );
			}
			target.add( 1 );
		}

		void logarithmicSplit(int amount,double near, double far, List<double> target ) {
			for (int i = 1; i < amount; i ++ ) {
				target.add((math.pow(near * ( far / near ),( i / amount ) ) / far ));
			}
			target.add( 1 );
		}

		void practicalSplit(int amount,double near,double far, lambda,List<double> target ) {
			_uniformArray.length = 0;
			_logArray.length = 0;
			logarithmicSplit( amount, near, far, _logArray );
			uniformSplit( amount, near, far, _uniformArray );

			for (int i = 1; i < amount; i ++ ) {
        target.add((1 - lambda) * _uniformArray[ i - 1 ] + lambda * _logArray[ i - 1 ]);
			}

			target.add( 1 );
		}

	void getBreaks() {
		final camera = data.camera;
		final far = math.min( camera.far, data.maxFar );
		breaks.length = 0;

		switch ( data.mode ) {

			case CSMMode.uniform:
				uniformSplit( data.cascades, camera.near, far, breaks );
				break;
			case CSMMode.logarithmic:
				logarithmicSplit( data.cascades, camera.near, far, breaks );
				break;
			case CSMMode.practical:
				practicalSplit( data.cascades, camera.near, far, 0.5, breaks );
				break;
			case CSMMode.custom:
				if ( data.customSplitsCallback == null ) console.error( 'CSM: Custom split scheme callback not defined.' );
				data.customSplitsCallback?.call(data.cascades, camera.near, far, breaks);
				break;
		}
  }



	void update() {
		final camera = data.camera;
		final frustums = this.frustums;

		// for each frustum we need to find its min-max box aligned with the light orientation
		// the position in _lightOrientationMatrix does not matter, as we transform there and back
		_lightOrientationMatrix.lookAt( Vector3(), data.lightDirection, _up );
		_lightOrientationMatrixInverse.setFrom( _lightOrientationMatrix ).invert();

		for (int i = 0; i < frustums.length; i ++ ) {

			final light = lights[ i ];
			final shadowCam = light.shadow?.camera;
			final texelWidth = ( shadowCam!.right - shadowCam.left ) / data.shadowMapSize;
			final texelHeight = ( shadowCam.top - shadowCam.bottom ) / data.shadowMapSize;
			_cameraToLightMatrix.multiply2( _lightOrientationMatrixInverse, camera.matrixWorld );
			frustums[ i ].toSpace( _cameraToLightMatrix, _lightSpaceFrustum );

			final nearVerts = _lightSpaceFrustum.vertices.near;
			final farVerts = _lightSpaceFrustum.vertices.far;
			_bbox.empty();
			for (int j = 0; j < 4; j ++ ) {

				_bbox.expandByPoint( nearVerts[ j ] );
				_bbox.expandByPoint( farVerts[ j ] );

			}

			_bbox.getCenter( _center );
			_center.z = _bbox.max.z + data.lightMargin;
			_center.x = ( _center.x / texelWidth ).floor() * texelWidth;
			_center.y = ( _center.y / texelHeight ).floor() * texelHeight;
			_center.applyMatrix4( _lightOrientationMatrix );

			light.position.setFrom( _center );
			light.target?.position.setFrom( _center );

			light.target?.position.x += data.lightDirection.x;
			light.target?.position.y += data.lightDirection.y;
			light.target?.position.z += data.lightDirection.z;
		}
	}

	void injectInclude() {
		lightsFragmentBegin = csmShader['lights_fragment_begin']!;
		lightsParsBegin = csmShader['lights_pars_begin']!;
	}

	void setupMaterial(Material material) {

		material.defines = material.defines ?? {};
		material.defines!['USE_CSM'] = 1;
		material.defines!['CSM_CASCADES'] = data.cascades;

		if (fade ) {
			material.defines!['CSM_FADE'] = '';
		}

		final List<Vector2> breaksVec2 = [];
		final scope = data;
		final shaders = this.shaders;

		material.onBeforeCompile = ( shader,target ) {
      shader as WebGLParameters;
			final far = math.min( scope.camera.far, scope.maxFar );
			getExtendedBreaks( breaksVec2 );

			shader.uniforms!['CSM_cascades'] = { ['value']: breaksVec2 };
			shader.uniforms!['cameraNear'] = { ['value']: scope.camera.near };
			shader.uniforms!['shadowFar'] = { ['value']: far };

			shaders[material] = shader;//.set material, shader );
		};

		shaders[material] = null;//.set( material, null );
	}

	void updateUniforms() {
		final far = math.min( data.camera.far, data.maxFar );
		final shaders = this.shaders;

		shaders.forEach((material,shader ) {
      shader as WebGLParameters?;
      material as Material;
			if ( shader != null ) {
				final uniforms = shader.uniforms;
				getExtendedBreaks( uniforms!['CSM_cascades']['value'] );
				uniforms['cameraNear']['value'] = data.camera.near;
				uniforms['shadowFar']['value'] = far;
			}

			if ( !fade && material.defines != null && material.defines!.containsKey('CSM_FADE')) {//'CSM_FADE' in material.defines
				//delete material.defines.CSM_FADE;
        material.defines?.remove('CSM_FADE');
				material.needsUpdate = true;
			} else if(fade && material.defines != null && !material.defines!.containsKey('CSM_FADE')) {
				material.defines!['CSM_FADE'] = '';
				material.needsUpdate = true;
			}
		});

	}

	void getExtendedBreaks(List<Vector2> target ) {
		while ( target.length < breaks.length ) {
			target.add( Vector2() );
		}

		target.length = breaks.length;

		for (int i = 0; i < data.cascades; i ++ ) {
			final amount = breaks[ i ];
			final prev = i == 0?0.0: breaks[ i - 1 ];
			target[ i ].x = prev;
			target[ i ].y = amount;
		}
	}

	void updateFrustums() {
		getBreaks();
		initCascades();
		updateShadowBounds();
		updateUniforms();
	}

	void remove() {
		for (int i = 0; i < lights.length; i ++ ) {
			data.parent.remove(lights[ i ].target! );
			data.parent.remove(lights[ i ] );
		}
	}

	void dispose() {
		final shaders = this.shaders;
		shaders.forEach((material,shader ) {
      shader as WebGLParameters?;
      material as Material;
			//material.onBeforeCompile;
			material.defines?.remove('USE_CSM');
			material.defines?.remove('CSM_CASCADES');
			material.defines?.remove('CSM_FADE');

			if ( shader != null ) {
				shader.uniforms?.remove('CSM_cascades');
				shader.uniforms?.remove('cameraNear');
				shader.uniforms?.remove('shadowFar');
			}

			material.needsUpdate = true;
		} );
		shaders.clear();
	}
}
