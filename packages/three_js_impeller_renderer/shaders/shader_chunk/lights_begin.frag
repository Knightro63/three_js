#version 460 core

// Binding 0: Frame uniforms
layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 viewMatrix;
    bool isOrthographic;
};

// Location 13: View-space position (Sequential after Fog at 12)
layout(location = 13) in vec3 vViewPosition;

/**
 * Note: PBR structs (IncidentLight, ReflectedLight, Material) 
 * and Light info functions must be available via common.frag or lights_pars.frag.
 */

void main() {
    // Setup Geometry
    vec3 geometryPosition = -vViewPosition;
    vec3 geometryNormal = normalize(vNormal); // from Location 3
    vec3 geometryViewDir = (isOrthographic) ? vec3(0.0, 0.0, 1.0) : normalize(vViewPosition);
    
    vec3 geometryClearcoatNormal = vec3(0.0);
    #ifdef USE_CLEARCOAT
        geometryClearcoatNormal = clearcoatNormal;
    #endif

    // Iridescence Logic
    #ifdef USE_IRIDESCENCE
        float dotNVi = saturate(dot(geometryNormal, geometryViewDir));
        if (material.iridescenceThickness == 0.0) {
            material.iridescence = 0.0;
        } else {
            material.iridescence = saturate(material.iridescence);
        }
        if (material.iridescence > 0.0) {
            material.iridescenceFresnel = evalIridescence(1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor);
            // This helper should be in your PBR math library
            material.iridescenceF0 = Schlick_to_F0(material.iridescenceFresnel, 1.0, dotNVi);
        }
    #endif

    IncidentLight directLight;

    // --- POINT LIGHTS ---
    for (int i = 0; i < numPointLights; i++) {
        getPointLightInfo(pointLights[i], geometryPosition, directLight);
        // Shadow logic would be called here using pointShadowMap[i]
        RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }

    // --- SPOT LIGHTS ---
    for (int i = 0; i < numSpotLights; i++) {
        getSpotLightInfo(spotLights[i], geometryPosition, directLight);
        // Optional Spot Light Map logic
        RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }

    // --- DIRECTIONAL LIGHTS ---
    for (int i = 0; i < numDirectionalLights; i++) {
        getDirectionalLightInfo(directionalLights[i], directLight);
        RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
    }

    // --- INDIRECT LIGHTING ---
    vec3 iblIrradiance = vec3(0.0);
    vec3 irradiance = getAmbientLightIrradiance(ambientLightColor);
    
    for (int i = 0; i < numHemiLights; i++) {
        irradiance += getHemisphereLightIrradiance(hemisphereLights[i], geometryNormal);
    }

    // Radiance init
    vec3 radiance = vec3(0.0);
    vec3 clearcoatRadiance = vec3(0.0);
}
