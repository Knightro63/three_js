#version 460 core

/**
 * Note: Requires inverseTransformDirection from common.frag.
 * Requires matrices and structs from shadowmap_pars.vert.
 */

layout(location = 29) out vec4 vDirectionalShadowCoord;
layout(location = 33) out vec4 vSpotLightCoord;
layout(location = 37) out vec4 vPointShadowCoord;

/**
 * Converts shadowmapVertex logic.
 * Calculates coordinates for all light types with normal bias offsets.
 */
void applyShadowMapVertex(
    vec4 worldPosition, 
    vec3 transformedNormal, 
    mat4 viewMatrix
) {
    // 1. Calculate the normal in world space for bias offsetting
    vec3 shadowWorldNormal = inverseTransformDirection(transformedNormal, viewMatrix);
    vec4 shadowWorldPosition;

    // --- Directional Shadows ---
    for (int i = 0; i < uNumDirectionalShadows; i++) {
        // Offset position along normal to reduce acne
        shadowWorldPosition = worldPosition + vec4(shadowWorldNormal * directionalLightShadows[i].shadowNormalBias, 0.0);
        vDirectionalShadowCoord[i] = directionalShadowMatrix[i] * shadowWorldPosition;
    }

    // --- Point Shadows ---
    for (int i = 0; i < uNumPointShadows; i++) {
        shadowWorldPosition = worldPosition + vec4(shadowWorldNormal * pointLightShadows[i].shadowNormalBias, 0.0);
        vPointShadowCoord[i] = pointShadowMatrix[i] * shadowWorldPosition;
    }

    // --- Spot Shadows / Light Coords ---
    for (int i = 0; i < uNumSpotLightCoords; i++) {
        shadowWorldPosition = worldPosition;
        
        // Only apply normal bias if the spot light actually casts a shadow
        if (i < uNumSpotShadows) {
            shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[i].shadowNormalBias;
        }
        
        vSpotLightCoord[i] = spotLightMatrix[i] * shadowWorldPosition;
    }
}
