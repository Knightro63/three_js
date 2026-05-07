#version 460 core

/**
 * Part of MaterialUniforms (Binding 1).
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous material uniforms
    float logDepthBufFC; // 2.0 / log2( far + 1.0 )
};

/**
 * Location 21: Perspective toggle (0.0 for Ortho, 1.0 for Perspective).
 * Sequential after vAnisotropyMapUv (20).
 */
layout(location = 21) in float vIsPerspective;

/**
 * Location 22: High-precision depth value passed from vertex shader.
 */
layout(location = 22) in float vFragDepth;
