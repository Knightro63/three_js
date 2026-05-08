
/**
 * Location 13: Fragment position in view space.
 * Sequential after vFogDepth (12).
 */
layout(location = 13) in vec3 vViewPosition;

/**
 * Note: Requires BRDF_Lambert from common.frag
 */

void RE_Direct_Lambert(
    const in IncidentLight directLight,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in LambertMaterial material,
    inout ReflectedLight reflectedLight
) {
    float dotNL = saturate(dot(geometryNormal, directLight.direction));
    vec3 irradiance = dotNL * directLight.color;
    
    reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
}

void RE_IndirectDiffuse_Lambert(
    const in vec3 irradiance,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in LambertMaterial material,
    inout ReflectedLight reflectedLight
) {
    reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
}
