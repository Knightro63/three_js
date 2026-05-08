
/**
 * Location 13: Fragment position in view space (Sequential).
 */
layout(location = 13) in vec3 vViewPosition;

/**
 * Note: Requires 
 * - getGradientIrradiance() from gradientmap_pars.frag
 * - BRDF_Lambert() from common.frag
 */

struct ToonMaterial {
    vec3 diffuseColor;
};

void RE_Direct_Toon(
    const in IncidentLight directLight,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in ToonMaterial material,
    inout ReflectedLight reflectedLight
) {
    // Stepped irradiance using the gradient map (Binding 13)
    vec3 irradiance = getGradientIrradiance(geometryNormal, directLight.direction, true) * directLight.color;
    
    reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
}

void RE_IndirectDiffuse_Toon(
    const in vec3 irradiance,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in ToonMaterial material,
    inout ReflectedLight reflectedLight
) {
    reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
}
