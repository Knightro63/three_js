#version 460 core

// 1. UNIFORMS BLOCK
// Keeping this block aligned immediately behind your 32-slot base vertex matrix registers.
uniform BlurUniforms {
    float v; // Vertical blur step offset size scalar
};

// 2. TEXTURE SAMPLERS
uniform sampler2D tDiffuse; // Sampler Index 0 (Decoupled from float arrays)

// 3. PIPELINE INPUTS (Implicit varying matching from vertex stage)
in vec2 vUv;

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 sum = vec4(0.0);

    // Modern GLSL handles standard overloads implicitly via texture()
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y - 4.0 * v)) * 0.051;
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y - 3.0 * v)) * 0.0918;
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y - 2.0 * v)) * 0.12245;
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y - 1.0 * v)) * 0.1531;
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y           )) * 0.1633;
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y + 1.0 * v)) * 0.1531;
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y + 2.0 * v)) * 0.12245;
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y + 3.0 * v)) * 0.0918;
    sum += texture(tDiffuse, vec2(vUv.x, vUv.y + 4.0 * v)) * 0.051;

    fragColor = sum;
}
