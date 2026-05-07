#version 460 core

// Binding 28: Dedicated sampler for the Roughness map
layout(set = 0, binding = 28) uniform sampler2D roughnessMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float roughness;
};

// Location 28: UV coordinates for Roughness (Sequential after vNormalMapUv at 27)
layout(location = 28) in vec2 vRoughnessMapUv;

/**
 * Converts roughnessmapFragment logic.
 * Reads the Green channel for ORM (Occlusion/Roughness/Metallic) compatibility.
 */
float getRoughness(bool useRoughnessMap) {
    float roughnessFactor = roughness;

    if (useRoughnessMap) {
        vec4 texelRoughness = texture(roughnessMap, vRoughnessMapUv);
        // Compatible with combined ORM textures (R=AO, G=Roughness, B=Metalness)
        roughnessFactor *= texelRoughness.g;
    }

    return roughnessFactor;
}
