
/**
 * Converts lightsFragmentEnd logic.
 * Finalizes the reflectedLight components by applying indirect Render Equations.
 * 
 * Note: RE_IndirectDiffuse and RE_IndirectSpecular must be defined 
 * in your chosen material model (e.g., physical_brdf.frag).
 */
void finalizeLighting(
    vec3 irradiance,
    vec3 radiance,
    vec3 iblIrradiance,
    vec3 clearcoatRadiance,
    vec3 geometryPosition,
    vec3 geometryNormal,
    vec3 geometryViewDir,
    vec3 geometryClearcoatNormal,
    Material material,
    inout ReflectedLight reflectedLight
) {
    // Apply Indirect Diffuse (Ambient, Hemi, LightProbes)
    RE_IndirectDiffuse(
        irradiance, 
        geometryPosition, 
        geometryNormal, 
        geometryViewDir, 
        geometryClearcoatNormal, 
        material, 
        reflectedLight
    );

    // Apply Indirect Specular (IBL, Environment Maps)
    RE_IndirectSpecular(
        radiance, 
        iblIrradiance, 
        clearcoatRadiance, 
        geometryPosition, 
        geometryNormal, 
        geometryViewDir, 
        geometryClearcoatNormal, 
        material, 
        reflectedLight
    );
}
