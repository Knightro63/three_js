#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float h; // 1.0 / width
};

// Binding 60: tDiffuse (Reusing map slot for post-processing source)
layout(binding = 60) uniform sampler2D tDiffuse;

// Location 53: vUv (Synced with Vertex 53 for background/post-processing isolation)
layout(location = 53) in vec2 vUv;

// Location 54: Final color redirected
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec4 sum = vec4( 0.0 );

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
