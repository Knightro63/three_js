#version 460 core

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float logDepthBufFC; // 2.0 / log2( far + 1.0 )
};

// Location 21: Perspective toggle (0.0 for Ortho, 1.0 for Perspective)
layout(location = 21) in float vIsPerspective;

// Location 22: High-precision depth value passed from vertex shader
layout(location = 22) in float vFragDepth;

/**
 * Converts logdepthbufFragment logic.
 * Manually writes to the depth buffer for custom depth scaling.
 */
void applyLogDepth() {
    // Doing a strict comparison with == 1.0 can cause noise artifacts.
    // vIsPerspective is treated as a float toggle.
    gl_FragDepth = (vIsPerspective == 0.0) 
        ? gl_FragCoord.z 
        : log2(vFragDepth) * logDepthBufFC * 0.5;
}
