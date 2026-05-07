#version 460 core

/**
 * Binding 10: Standard Environment Map sampler.
 * Supports both sampler2D (equirectangular/atlas) and samplerCube.
 * For Flutter GPU, we'll standardize on sampler2D for the atlas approach.
 */
layout(set = 0, binding = 10) uniform sampler2D envMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous material uniforms
    float envMapIntensity;
    float flipEnvMap;
    mat3 envMapRotation;
};
