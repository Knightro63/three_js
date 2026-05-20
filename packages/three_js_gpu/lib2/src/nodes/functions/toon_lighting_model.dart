import '../core/lighting_model.dart';

getGradientIrradiance({ normal, lightDirection, builder } ){
	// dotNL will be from -1.0 to 1.0
	final dotNL = normal.dot( lightDirection );
	final coord = vec2( dotNL.mul( 0.5 ).add( 0.5 ), 0.0 );

	if ( builder.material.gradientMap ) {
		final gradientMap = materialReference( 'gradientMap', 'texture' ).context( { getUV: () => coord } );
		return vec3( gradientMap.r );
	} 
  else {
		final fw = coord.fwidth().mul( 0.5 );
		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( float( 0.7 ).sub( fw.x ), float( 0.7 ).add( fw.x ), coord.x ) );
	}
}

/**
 * Represents the lighting model for a toon material. Used in {@link MeshToonNodeMaterial}.
 *
 * @augments LightingModel
 */
class ToonLightingModel extends LightingModel {
	/**
	 * Implements the direct lighting. Instead of using a conventional smooth irradiance, the irradiance is
	 * reduced to a small number of discrete shades to create a comic-like, flat look.
	 *
	 * @param {Object} lightData - The light data.
	 * @param {NodeBuilder} builder - The current node builder.
	 */
  @override
	void direct( Map<String,dynamic> lightData, NodeBuilder builder ) {
		final irradiance = getGradientIrradiance( { 'normal': normalGeometry, 'lightDirection': lightDirection, 'builder': builder } ).mul( lightColor );
		reflectedLight.directDiffuse.addAssign( irradiance.mul( BRDF_Lambert( { 'diffuseColor': diffuseColor.rgb } ) ) );
	}

	/**
	 * Implements the indirect lighting.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	void indirect(NodeBuilder builder ) {
		final ambientOcclusion = builder.context.ambientOcclusion;
    final irradiance = builder.context.irradiance;
    final reflectedLight = builder.context.reflectedLight;

		reflectedLight.indirectDiffuse.addAssign( irradiance.mul( BRDF_Lambert( { diffuseColor } ) ) );
		reflectedLight.indirectDiffuse.mulAssign( ambientOcclusion );
	}
}


