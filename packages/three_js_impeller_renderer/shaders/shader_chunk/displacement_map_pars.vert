#version 460 core

/**
 * Binding 11: Dedicated sampler for the Displacement Map.
 * Usually a grayscale texture where pixel values shift vertex positions.
 */
layout(set = 0, binding = 11) uniform sampler2D displacementMap;

/**
 * Part of MaterialUniforms (Binding 1).
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... other uniforms
    float displacementScale;
    float displacementBias;
};
