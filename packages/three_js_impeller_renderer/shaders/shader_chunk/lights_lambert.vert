
/**
 * Outputs to Fragment Shader.
 * Pre-calculated light values (Gouraud Shading).
 */
layout(location = 13) out vec3 vViewPosition;   // Matches Frag Location 13
layout(location = 14) out vec3 vLightFront;      // Direct light intensity (Front)
layout(location = 15) out vec3 vIndirectFront;   // Indirect light intensity (Front)
layout(location = 16) out vec3 vLightBack;       // Direct light intensity (Back)
layout(location = 17) out vec3 vIndirectBack;    // Indirect light intensity (Back)

/**
 * Converts lightsLambertVertex logic.
 * Note: Requires light info functions (getPointLightInfo, etc.) from lights_pars.
 */
void calculateVertexLighting(
    vec4 mvPosition, 
    vec3 transformedNormal, 
    bool isOrthographic,
    bool isDoubleSided
) {
    vViewPosition = -mvPosition.xyz;

    GeometricContext geometry;
    geometry.position = mvPosition.xyz;
    geometry.normal = normalize(transformedNormal);
    geometry.viewDir = (isOrthographic) ? vec3(0.0, 0.0, 1.0) : normalize(-mvPosition.xyz);

    vLightFront = vec3(0.0);
    vIndirectFront = getAmbientLightIrradiance(ambientLightColor);
    
    // Initialize back-side if needed
    vLightBack = vec3(0.0);
    vIndirectBack = vec3(0.0);
    if (isDoubleSided) {
        vIndirectBack = getAmbientLightIrradiance(ambientLightColor);
    }

    IncidentLight directLight;

    // --- Point Lights ---
    for (int i = 0; i < uNumPointLights; i++) {
        getPointLightInfo(pointLights[i], geometry, directLight);
        float dotNL = dot(geometry.normal, directLight.direction);
        vLightFront += saturate(dotNL) * directLight.color;
        if (isDoubleSided) vLightBack += saturate(-dotNL) * directLight.color;
    }

    // --- Spot Lights ---
    for (int i = 0; i < uNumSpotLights; i++) {
        getSpotLightInfo(spotLights[i], geometry, directLight);
        float dotNL = dot(geometry.normal, directLight.direction);
        vLightFront += saturate(dotNL) * directLight.color;
        if (isDoubleSided) vLightBack += saturate(-dotNL) * directLight.color;
    }

    // --- Directional Lights ---
    for (int i = 0; i < uNumDirectionalLights; i++) {
        getDirectionalLightInfo(directionalLights[i], geometry, directLight);
        float dotNL = dot(geometry.normal, directLight.direction);
        vLightFront += saturate(dotNL) * directLight.color;
        if (isDoubleSided) vLightBack += saturate(-dotNL) * directLight.color;
    }

    // --- Hemisphere Lights ---
    for (int i = 0; i < uNumHemiLights; i++) {
        vIndirectFront += getHemisphereLightIrradiance(hemisphereLights[i], geometry.normal);
        if (isDoubleSided) {
            vIndirectBack += getHemisphereLightIrradiance(hemisphereLights[i], -geometry.normal);
        }
    }
}
