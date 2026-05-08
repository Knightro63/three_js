#version 460 core

/**
 * Stage: Fragment
 * Purpose: Vertical Gaussian Blur (9 samples).
 */

// Binding 58: tDiffuse (using t2D slot) per Master List
layout(set = 0, binding = 58) uniform sampler2D tDiffuse;

layout(std140, binding = 1) uniform MaterialUniforms {
    float v; // 1.0 / height
};

// Location 53: Interpolated UV per Master List
layout(location = 53) in vec2 vUv;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    vec4 sum = vec4( 0.0 );

    // 9-tap Gaussian filter along the Y axis
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y - 4.0 * v ) ) * 0.051;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y - 3.0 * v ) ) * 0.0918;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y - 2.0 * v ) ) * 0.12245;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y - 1.0 * v ) ) * 0.1531;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y + 1.0 * v ) ) * 0.1531;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y + 2.0 * v ) ) * 0.12245;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y + 3.0 * v ) ) * 0.0918;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y + 4.0 * v ) ) * 0.051;

    pc_fragColor = sum;
}
