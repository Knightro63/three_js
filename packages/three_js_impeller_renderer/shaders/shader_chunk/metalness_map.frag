
// Binding 24: Dedicated sampler for the Metalness map
layout(set = 0, binding = 24) uniform sampler2D metalnessMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float metalness;
};

// Location 24: UV coordinates for Metalness (Sequential after vMapUv at 23)
layout(location = 24) in vec2 vMetalnessMapUv;

/**
 * Converts metalnessmapFragment logic.
 * Reads the Blue channel to remain compatible with ORM (Occlusion/Roughness/Metallic) textures.
 */
float getMetalness(bool useMetalnessMap) {
    float metalnessFactor = metalness;

    if (useMetalnessMap) {
        vec4 texelMetalness = texture(metalnessMap, vMetalnessMapUv);
        // Compatible with combined ORM textures (R=AO, G=Roughness, B=Metalness)
        metalnessFactor *= texelMetalness.b;
    }

    return metalnessFactor;
}
