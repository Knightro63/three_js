#version 460 core

/**
 * Part of MaterialUniforms (Binding 1).
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous material uniforms
    float reflectivity;
    float refractionRatio;
};

/**
 * Location 10: Interpolated world-space position.
 * Used when ENV_WORLDPOS logic is active (e.g., with Normal/Bump maps).
 */
layout(location = 10) in vec3 vWorldPosition;

/**
 * Location 11: Pre-calculated reflection vector from the vertex shader.
 * Used as a fallback when world position is not required.
 */
layout(location = 11) in vec3 vReflect;
