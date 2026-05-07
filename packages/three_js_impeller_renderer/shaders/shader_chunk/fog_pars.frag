#version 460 core

/**
 * Part of MaterialUniforms (Binding 1).
 * Grouping all fog parameters together for buffer efficiency.
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous material uniforms
    vec3 fogColor;
    float fogDensity;
    float fogNear;
    float fogFar;
};

/**
 * Location 12: Interpolated depth from vertex shader.
 */
layout(location = 12) in float vFogDepth;
