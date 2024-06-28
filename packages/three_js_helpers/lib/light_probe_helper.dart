import 'package:three_js_core/three_js_core.dart';

/// Renders a sphere to visualize a light probe in the scene.
/// 
/// ```
/// final helper = LightProbeHelper( lightProbe, 1 );
/// scene.add( helper );
/// ```
class LightProbeHelper extends Mesh {
  late LightProbe lightProbe;
  late double size;

  /// [lightProbe] -- the light probe.
  /// 
  /// [size] -- size of the helper sphere
  LightProbeHelper.create(super.geometry, super.material, this.lightProbe, this.size){
    type = 'LightProbeHelper';
		onBeforeRender.call();
  }

	factory LightProbeHelper(LightProbe lightProbe, double size){
		final material = ShaderMaterial.fromMap( {
			//'type': 'LightProbeHelperMaterial',
			'uniforms': {
				'sh': { 'value': lightProbe.sh?.coefficients }, // by reference
				'intensity': { 'value': lightProbe.intensity }
			},

			'vertexShader': [
				'varying vec3 vNormal;',
				'void main() {',
				'	vNormal = normalize( normalMatrix * normal );',
				'	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
				'}',
			].join( '\n' ),

			'fragmentShader': [
				'#define RECIPROCAL_PI 0.318309886',
				'vec3 inverseTransformDirection( in vec3 normal, in mat4 matrix ) {',
				'	// matrix is assumed to be orthogonal',
				'	return normalize( ( vec4( normal, 0.0 ) * matrix ).xyz );',
				'}',

				'// source: https://graphics.stanford.edu/papers/envmap/envmap.pdf',
				'vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {',
				'	// normal is assumed to have unit length',
				'	float x = normal.x, y = normal.y, z = normal.z;',
				'	// band 0',
				'	vec3 result = shCoefficients[ 0 ] * 0.886227;',
				'	// band 1',
				'	result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;',
				'	result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;',
				'	result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;',
				'	// band 2',
				'	result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;',
				'	result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;',
				'	result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );',
				'	result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;',
				'	result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );',
				'	return result;',
				'}',

				'uniform vec3 sh[ 9 ]; // sh coefficients',
				'uniform float intensity; // light probe intensity',
				'varying vec3 vNormal;',

				'void main() {',
				'	vec3 normal = normalize( vNormal );',
				'	vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );',
				'	vec3 irradiance = shGetIrradianceAt( worldNormal, sh );',
				'	vec3 outgoingLight = RECIPROCAL_PI * irradiance * intensity;',
				'	gl_FragColor = linearToOutputTexel( vec4( outgoingLight, 1.0 ) );',
				'}'

			].join( '\n' )
		});

		final geometry = SphereGeometry( 1, 32, 16 );
    final lph = LightProbeHelper.create(geometry, material,lightProbe,size);

    return lph;
	}

  /// Frees the GPU-related resources allocated by this instance. Call this method whenever this instance is no longer used in your app.
  @override
	void dispose() {
		geometry?.dispose();
		material?.dispose();
	}

  @override
	OnBeforeRender get onBeforeRender => ({
    WebGLRenderer? renderer,
    RenderTarget? renderTarget,
    Object3D? mesh,
    Scene? scene,
    Camera? camera,
    BufferGeometry? geometry,
    Material? material,
    Map<String, dynamic>? group
  }) {
		position.setFrom( lightProbe.position );
		scale.setValues( 1, 1, 1 ).scale(size);
		material?.uniforms['intensity']['value'] = lightProbe.intensity;
	};
}
