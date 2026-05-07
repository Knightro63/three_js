#version 460 core

// Binding 6: Dedicated sampler for the Clearcoat Normal map
layout(set = 0, binding = 6) uniform sampler2D clearcoatNormalMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... other uniforms
    float clearcoatNormalScale;
};

// Location 6: UV coordinates for Clearcoat Normal Map
layout(location = 6) in vec2 vClearcoatNormalMapUv;

/**
 * Converts clearcoatNormalFragmentMaps logic.
 * Note: tbn2 is the Tangent-Bitangent-Normal matrix for the clearcoat layer.
 */
vec3 applyClearcoatNormalMap(vec3 currentClearcoatNormal, mat3 tbn2) {
    // texture2D -> texture in 4.60
    vec3 clearcoatMapN = texture(clearcoatNormalMap, vClearcoatNormalMapUv).xyz * 2.0 - 1.0;
    
    clearcoatMapN.xy *= clearcoatNormalScale;
    
    return normalize(tbn2 * clearcoatMapN);
}
