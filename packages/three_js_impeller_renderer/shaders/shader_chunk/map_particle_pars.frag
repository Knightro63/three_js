#version 460 core

/**
 * Binding 4: Primary Diffuse Map.
 * Binding 2: Alpha Map.
 */
layout(set = 0, binding = 4) uniform sampler2D map;
layout(set = 0, binding = 2) uniform sampler2D alphaMap;

/**
 * Part of MaterialUniforms (Binding 1).
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    mat3 uvTransform; 
};

/**
 * Location 23: Vertex-based UVs for particles (Sequential).
 */
layout(location = 23) in vec2 vUv;
