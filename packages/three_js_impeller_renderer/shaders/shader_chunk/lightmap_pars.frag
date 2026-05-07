#version 460 core

/**
 * Binding 16: Dedicated sampler for the Light Map.
 * Typically used for baked global illumination.
 */
layout(set = 0, binding = 16) uniform sampler2D lightMap;

/**
 * Part of MaterialUniforms (Binding 1).
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous material uniforms
    float lightMapIntensity;
};
