import 'package:three_js/three_js.dart';

/**
 * ------------------------------------------------------------------------------------------
 * Subsurface Scattering shader
 * Based on GDC 2011 – Approximating Translucency for a Fast, Cheap and Convincing Subsurface Scattering Look
 * https://colinbarrebrisebois.com/2011/03/07/gdc-2011-approximating-translucency-for-a-fast-cheap-and-convincing-subsurface-scattering-look/
 *------------------------------------------------------------------------------------------
 */

replaceAll(String string,String find,String replace ) {
	return string.split( find ).join( replace );
}

final String meshphongFragHead = shaderChunk[ 'meshphong_frag' ]!.substring( 0, shaderChunk[ 'meshphong_frag' ]!.indexOf( 'void main() {' ) );
final String meshphongFragBody = shaderChunk[ 'meshphong_frag' ]!.substring( shaderChunk[ 'meshphong_frag' ]!.indexOf( 'void main() {' ) );

final Map<String,dynamic> subsurfaceScatteringShader = {
	'name': 'SubsurfaceScatteringShader',
	'uniforms': UniformsUtils.merge( [
		shaderLib[ 'phong' ]['uniforms'],
		{
			'thicknessMap': <String,dynamic>{ 'value': null },
			'thicknessColor': { 'value': Color( 0xffffff ) },
			'thicknessDistortion': { 'value': 0.1 },
			'thicknessAmbient': { 'value': 0.0 },
			'thicknessAttenuation': { 'value': 0.1 },
			'thicknessPower': { 'value': 2.0 },
			'thicknessScale': { 'value': 10.0 }
		}

	] ),
	'vertexShader': [
		'#define USE_UV',
		shaderChunk[ 'meshphong_vert' ],
	].join( '\n' ),

	'fragmentShader': [
		'#define USE_UV',
		'#define SUBSURFACE',

		meshphongFragHead,

		'uniform sampler2D thicknessMap;',
		'uniform float thicknessPower;',
		'uniform float thicknessScale;',
		'uniform float thicknessDistortion;',
		'uniform float thicknessAmbient;',
		'uniform float thicknessAttenuation;',
		'uniform vec3 thicknessColor;',

		'void RE_Direct_Scattering(const in IncidentLight directLight, const in vec2 uv, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, inout ReflectedLight reflectedLight) {',
		'	vec3 thickness = thicknessColor * texture2D(thicknessMap, uv).r;',
		'	vec3 scatteringHalf = normalize(directLight.direction + (geometryNormal * thicknessDistortion));',
		'	float scatteringDot = pow(saturate(dot(geometryViewDir, -scatteringHalf)), thicknessPower) * thicknessScale;',
		'	vec3 scatteringIllu = (scatteringDot + thicknessAmbient) * thickness;',
		'	reflectedLight.directDiffuse += scatteringIllu * thicknessAttenuation * directLight.color;',
		'}',

		meshphongFragBody.replaceAll( '#include <lights_fragment_begin>',

			replaceAll(
				shaderChunk[ 'lights_fragment_begin' ]!,
				'RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );',
				[
					'RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );',

					'#if defined( SUBSURFACE ) && defined( USE_UV )',
					' RE_Direct_Scattering(directLight, vUv, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, reflectedLight);',
					'#endif',
				].join( '\n' )
			),

		),

	].join( '\n' ),

};
