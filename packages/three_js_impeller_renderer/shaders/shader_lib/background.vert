#version 460 core

/**
 * Stage: Vertex
 * Purpose: Fullscreen 2D background plane.
 */

// 1. ATTRIBUTES (Inputs)
layout(location = 0)  in vec3 inPosition;
layout(location = 29) in vec2 inUv; // Primary UV set per Master List

// 2. VARYINGS (Outputs)
layout(location = 53) out vec2 vUv; // Synced with Frag 53

// 3. UNIFORMS
layout(set = 0, binding = 1) uniform MaterialUniforms {
    mat3 uvTransform;
};

void main() {
    // Apply UV transformation for tiling/offsetting background textures
    vUv = (uvTransform * vec3(inUv, 1.0)).xy;

    // Standard fullscreen quad position logic
    // Z is set to 1.0 to ensure it sits at the far plane
    gl_Position = vec4(inPosition.xy, 1.0, 1.0);
}
