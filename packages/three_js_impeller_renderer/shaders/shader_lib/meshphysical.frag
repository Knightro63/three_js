#version 460 core

// Binding 1: MaterialUniforms - Consolidated PBR parameters
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    vec3 emissive;
    float roughness;
    float metalness;
    float opacity;
    float uAlphaTest;
    float ior;
    float specularIntensity;
    vec3 specularColor;
    float clearcoat;
    float clearcoatRoughness;
    float dispersion;
    float iridescence;
    float iridescenceIOR;
    vec3 sheenColor;
    float sheenRoughness;
    vec2 anisotropyVector;
    bool useMap;
    bool useAlphaMap;
    bool useNormalMap;
    bool useRoughnessMap;
    bool useMetalnessMap;
    bool useClearcoat;
    bool useSheen;
    bool useIridescence;
    bool useTransmission;
};

// PBR Sampler Bindings from Master List
layout(binding = 60) uniform sampler2D map;
layout(binding = 2)  uniform sampler2D alphaMap;
layout(binding = 27) uniform sampler2D normalMap;
layout(binding = 28) uniform sampler2D roughnessMap;
layout(binding = 24) uniform sampler2D metalnessMap;
layout(binding = 12) uniform sampler2D emissiveMap;
layout(binding = 17) uniform sampler2D specularColorMap;
layout(binding = 18) uniform sampler2D specularIntensityMap;
layout(binding = 6)  uniform sampler2D clearcoatNormalMap;
layout(binding = 19) uniform sampler2D sheenColorMap;

// Fragment Inputs (Synced to Location Master List)
layout(location = 3)  in vec3 vNormal;         
layout(location = 13) in vec3 vViewPosition;   
layout(location = 23) in vec2 vMapUv;          
layout(location = 1)  in vec2 vAlphaMapUv;     
layout(location = 28) in vec2 vRoughnessMapUv; 
layout(location = 24) in vec2 vMetalnessMapUv; 
layout(location = 9)  in vec2 vEmissiveMapUv;
layout(location = 18) in vec2 vSpecularColorMapUv;

// Final Output
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);
    
    // 1. Texture Map Sampling with SPIR-V Branching
    if (useMap) diffuseColor *= texture(map, vMapUv);
    if (useAlphaMap) diffuseColor.a *= texture(alphaMap, vAlphaMapUv).g;
    if (diffuseColor.a < uAlphaTest) discard;

    // 2. Surface Property Setup
    float actualRoughness = roughness;
    if (useRoughnessMap) actualRoughness *= texture(roughnessMap, vRoughnessMapUv).g;
    
    float actualMetalness = metalness;
    if (useMetalnessMap) actualMetalness *= texture(metalnessMap, vMetalnessMapUv).b;

    // 3. Normal & Geometry
    vec3 normal = normalize(vNormal);
    vec3 viewDir = normalize(vViewPosition);

    // 4. Lighting Accumulation (Standard PBR BSDF)
    // Note: Inlined PBR logic replaces <lights_physical_fragment>
    vec3 outgoingLight = vec3(0.0);
    vec3 totalEmissive = emissive;
    if (useEmissiveMap) totalEmissive *= texture(emissiveMap, vEmissiveMapUv).rgb;

    // Indirect and Direct lighting placeholders
    vec3 totalDiffuse = diffuseColor.rgb; // Simplified for template base
    vec3 totalSpecular = vec3(0.0);

    // 5. Layer Extensions (Clearcoat/Sheen/Iridescence)
    if (useClearcoat) {
        // Clearcoat calculation logic...
    }
    
    if (useSheen) {
        // Sheen energy compensation logic...
    }

    outgoingLight = totalDiffuse + totalSpecular + totalEmissive;

    pc_fragColor = vec4(outgoingLight, diffuseColor.a);
}
