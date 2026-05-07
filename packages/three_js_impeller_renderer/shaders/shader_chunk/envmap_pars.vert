#version 460 core

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float refractionRatio;
};

/**
 * Location 10: World-space position output.
 */
layout(location = 6) out vec3 vWorldPosition;

/**
 * Location 11: Pre-calculated reflection vector output.
 */
layout(location = 7) out vec3 vReflect;
