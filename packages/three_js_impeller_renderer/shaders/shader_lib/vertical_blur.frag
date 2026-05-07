#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float v; // 1.0 / height
};

// Binding 60: tDiffuse (Source texture)
layout(binding = 60) uniform sampler2D tDiffuse;

// Location 53: vUv (Synced with Vertex 31)
layout(location = 53) in vec2 vUv;

// Location 54: Final color output
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec4 sum = vec4( 0.0 );

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
