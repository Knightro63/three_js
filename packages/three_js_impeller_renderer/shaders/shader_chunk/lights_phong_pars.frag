#version 460 core

/**
 * Location 13: Fragment position in view space (Sequential).
 */
layout(location = 13) in vec3 vViewPosition;

/**
 * Note: Requires BRDF_Lambert and BRDF_BlinnPhong from common.frag/bsdfs.frag
 */

struct BlinnPhongMaterial {
    vec3 diffuseColor;
    vec3 specularColor;
    float specularShininess;
    float specularStrength;
};

void RE_Direct_BlinnPhong(
    const in IncidentLight directLight,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in BlinnPhongMaterial material,
    inout ReflectedLight reflectedLight
) {
    float dotNL = saturate(dot(geometryNormal, directLight.direction));
    vec3 irradiance = dotNL * directLight.color;

    reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
    
    reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong(
        directLight.direction, 
        geometryViewDir, 
        geometryNormal, 
        material.specularColor, 
        material.specularShininess
    ) * material.specularStrength;
}

void RE_IndirectDiffuse_BlinnPhong(
    const in vec3 irradiance,
    const in vec3 geometryPosition,
    const in vec3 geometryNormal,
    const in vec3 geometryViewDir,
    const in vec3 geometryClearcoatNormal,
    const in BlinnPhongMaterial material,
    inout ReflectedLight reflectedLight
) {
    reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
}
