#version 460 core

/**
 * Stage: Fragment
 * Purpose: Horizontal Gaussian Blur (9 samples).
 */

// Binding 58: tDiffuse (using t2D slot) per Master List
layout(set = 0, binding = 58) uniform sampler2D tDiffuse;

layout(std140, binding = 1) uniform MaterialUniforms {
    float h; // 1.0 / width
};

// Location 53: Interpolated UV per Master List
layout(location = 53) in vec2 vUv;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    vec4 sum = vec4( 0.0 );

    // 9-tap Gaussian filter
    sum += texture( tDiffuse, vec2( vUv.x - 4.0 * h, vUv.y ) ) * 0.051;
    sum += texture( tDiffuse, vec2( vUv.x - 3.0 * h, vUv.y ) ) * 0.0918;
    sum += texture( tDiffuse, vec2( vUv.x - 2.0 * h, vUv.y ) ) * 0.12245;
    sum += texture( tDiffuse, vec2( vUv.x - 1.0 * h, vUv.y ) ) * 0.1531;
    sum += texture( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;
    sum += texture( tDiffuse, vec2( vUv.x + 1.0 * h, vUv.y ) ) * 0.1531;
    sum += texture( tDiffuse, vec2( vUv.x + 2.0 * h, vUv.y ) ) * 0.12245;
    sum += texture( tDiffuse, vec2( vUv.x + 3.0 * h, vUv.y ) ) * 0.0918;
    sum += texture( tDiffuse, vec2( vUv.x + 4.0 * h, vUv.y ) ) * 0.051;

    pc_fragColor = sum;
}
