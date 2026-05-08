
// Textures - Continuing sequential bindings after LightMap (16)
layout(set = 0, binding = 17) uniform sampler2D specularColorMap;
layout(set = 0, binding = 18) uniform sampler2D specularIntensityMap;
layout(set = 0, binding = 19) uniform sampler2D sheenColorMap;
layout(set = 0, binding = 20) uniform sampler2D sheenRoughnessMap;
layout(set = 0, binding = 21) uniform sampler2D anisotropyMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    float metalnessFactor;
    float roughnessFactor;
    float ior;
    float specularIntensity;
    vec3 specularColor;
    float clearcoat;
    float clearcoatRoughness;
    float dispersion;
    float iridescence;
    float iridescenceIOR;
    float iridescenceThicknessMinimum;
    float iridescenceThicknessMaximum;
    vec3 sheenColor;
    float sheenRoughness;
    vec2 anisotropyVector;
};

// Updated Locations per your request
layout(location = 18) in vec2 vSpecularColorMapUv;
layout(location = 19) in vec2 vSheenColorMapUv;
layout(location = 20) in vec2 vAnisotropyMapUv;

/**
 * Initializes PhysicalMaterial state.
 * Requires Material struct, pow2(), and saturate() from common.frag.
 */
void initializePhysicalMaterial(inout Material material, vec4 diffuseColor, vec3 nonPerturbedNormal, mat3 tbn) {
    material.diffuseColor = diffuseColor.rgb * (1.0 - metalnessFactor);

    // Geometry roughness for anti-aliasing specular highlights
    vec3 dxy = max(abs(dFdx(nonPerturbedNormal)), abs(dFdy(nonPerturbedNormal)));
    float geometryRoughness = max(max(dxy.x, dxy.y), dxy.z);

    material.roughness = max(roughnessFactor, 0.0525) + geometryRoughness;
    material.roughness = min(material.roughness, 1.0);

    // IOR and Specular
    float specularIntensityFactor = specularIntensity;
    vec3 specularColorFactor = specularColor * texture(specularColorMap, vSpecularColorMapUv).rgb;
    specularIntensityFactor *= texture(specularIntensityMap, vSpecularColorMapUv).a; 

    material.specularF90 = mix(specularIntensityFactor, 1.0, metalnessFactor);
    material.specularColor = mix(min(pow2((ior - 1.0) / (ior + 1.0)) * specularColorFactor, vec3(1.0)) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor);

    // Clearcoat
    material.clearcoat = saturate(clearcoat); 
    material.clearcoatRoughness = max(clearcoatRoughness, 0.0525) + geometryRoughness;
    material.clearcoatRoughness = min(material.clearcoatRoughness, 1.0);

    // Sheen
    material.sheenColor = sheenColor * texture(sheenColorMap, vSheenColorMapUv).rgb;
    material.sheenRoughness = clamp(sheenRoughness * texture(sheenRoughnessMap, vSheenColorMapUv).a, 0.07, 1.0);

    // Anisotropy
    mat2 anisotropyMat = mat2(anisotropyVector.x, anisotropyVector.y, -anisotropyVector.y, anisotropyVector.x);
    vec3 anisotropyPolar = texture(anisotropyMap, vAnisotropyMapUv).rgb;
    vec2 anisotropyV = anisotropyMat * normalize(2.0 * anisotropyPolar.rg - vec2(1.0)) * anisotropyPolar.b;
    
    material.anisotropy = saturate(length(anisotropyV));
    vec2 unitAnisotropyV = (material.anisotropy == 0.0) ? vec2(1.0, 0.0) : anisotropyV / length(anisotropyV);

    material.alphaT = mix(pow2(material.roughness), 1.0, pow2(material.anisotropy));
    material.anisotropyT = tbn[0] * unitAnisotropyV.x + tbn[1] * unitAnisotropyV.y;
    material.anisotropyB = tbn[1] * unitAnisotropyV.x - tbn[0] * unitAnisotropyV.y;
}
