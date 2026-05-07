#version 460 core

/**
 * Converts lightsFragmentMaps logic.
 * Integrates IBL and Lightmaps into irradiance and radiance variables.
 */
void applyLightingMaps(
    inout vec3 irradiance,
    inout vec3 iblIrradiance,
    inout vec3 radiance,
    inout vec3 clearcoatRadiance,
    vec3 geometryNormal,
    vec3 geometryViewDir,
    vec3 geometryClearcoatNormal,
    Material material,
    bool useLightMap,
    bool useEnvMap,
    bool useAnisotropy,
    bool useClearcoat
) {
    // 1. Indirect Diffuse (Lightmaps)
    if (useLightMap) {
        // vUv2 is Location 2 as per Master List
        vec4 lightMapTexel = texture(lightMap, vUv2);
        vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
        irradiance += lightMapIrradiance;
    }

    // 2. IBL Irradiance (Diffuse environment lighting)
    if (useEnvMap) {
        // From envmap_physical_pars.frag
        iblIrradiance += getIBLIrradiance(geometryNormal);
    }

    // 3. Indirect Specular (Radiance)
    if (useEnvMap) {
        if (useAnisotropy) {
            radiance += getIBLAnisotropyRadiance(
                geometryViewDir, 
                geometryNormal, 
                material.roughness, 
                material.anisotropyB, 
                material.anisotropy
            );
        } else {
            radiance += getIBLRadiance(geometryViewDir, geometryNormal, material.roughness);
        }

        // 4. Clearcoat Radiance
        if (useClearcoat) {
            clearcoatRadiance += getIBLRadiance(
                geometryViewDir, 
                geometryClearcoatNormal, 
                material.clearcoatRoughness
            );
        }
    }
}
