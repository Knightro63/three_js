
/**
 * Binding 54: Dedicated sampler for the Specular map.
 */
layout(set = 0, binding = 54) uniform sampler2D specularMap;

/**
 * Location 41: UV coordinates for Specular mapping.
 * Sequentially placed after the shadow coordinate blocks.
 */
layout(location = 41) in vec2 vSpecularMapUv;

/**
 * Converts specularmapFragment logic.
 * Returns the specularStrength factor (Red channel).
 */
float getSpecularStrength(bool useSpecularMap) {
    if (useSpecularMap) {
        return texture(specularMap, vSpecularMapUv).r;
    }
    return 1.0;
}
