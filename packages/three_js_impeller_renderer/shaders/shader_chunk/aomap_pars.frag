
/**
 * Binding 3: Dedicated sampler for the Ambient Occlusion map.
 * compatible with combined OcclusionRoughnessMetallic (ORM) textures.
 */
layout(set = 0, binding = 3) uniform sampler2D aoMap;

/**
 * Part of MaterialUniforms (Binding 1).
 * Grouped with other material scalars for buffer efficiency.
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... other uniforms (uDiffuseColor, uAlphaTest, etc.)
    float aoMapIntensity;
};
