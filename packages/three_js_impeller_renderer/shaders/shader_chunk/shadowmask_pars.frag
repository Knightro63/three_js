
/**
 * Aggregates all shadow contributions into a single mask.
 * Requires getShadow and getPointShadow from shadowmap_pars.frag.
 */

float getShadowMask() {
    float shadow = 1.0;

    // uNumDirectionalShadows etc. should be in FrameUniforms (Binding 0)
    
    // --- Directional Shadows ---
    for (int i = 0; i < uNumDirectionalShadows; i++) {
        shadow *= receiveShadow ? getShadow(
            directionalShadowMap[i], 
            directionalLightShadows[i].shadowMapSize, 
            directionalLightShadows[i].shadowBias, 
            directionalLightShadows[i].shadowRadius, 
            vDirectionalShadowCoord[i],
            uShadowType // Uniform for PCF/VSM toggle
        ) : 1.0;
    }

    // --- Spot Shadows ---
    for (int i = 0; i < uNumSpotShadows; i++) {
        shadow *= receiveShadow ? getShadow(
            spotShadowMap[i], 
            spotLightShadows[i].shadowMapSize, 
            spotLightShadows[i].shadowBias, 
            spotLightShadows[i].shadowRadius, 
            vSpotLightCoord[i],
            uShadowType
        ) : 1.0;
    }

    // --- Point Shadows ---
    for (int i = 0; i < uNumPointShadows; i++) {
        shadow *= receiveShadow ? getPointShadow(
            pointShadowMap[i], 
            pointLightShadows[i].shadowMapSize, 
            pointLightShadows[i].shadowBias, 
            pointLightShadows[i].shadowRadius, 
            vPointShadowCoord[i], 
            pointLightShadows[i].shadowCameraNear, 
            pointLightShadows[i].shadowCameraFar
        ) : 1.0;
    }

    return shadow;
}
