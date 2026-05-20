#version 460 core

// 1. UNIFORMS BLOCK
// If this shader pairs with the 32-slot vertex shader from the previous step,
// this float variable will naturally start at Index 32.
uniform BlurUniforms {
    float h; // Blur step offset size scalar
};

// 2. TEXTURE SAMPLERS
uniform sampler2D tDiffuse; // Sampler Index 0 (Decoupled from float arrays)

// 3. PIPELINE INPUTS (Implicit varying matching)
in vec2 vUv;

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 sum = vec4(0.0);

    // Modern GLSL uses overloaded texture() sampling commands natively
    sum += texture(tDiffuse, vec2(vUv.x - 4.0 * h, vUv.y)) * 0.051;
    sum += texture(tDiffuse, vec2(vUv.x - 3.0 * h, vUv.y)) * 0.0918;
    sum += texture(tDiffuse, vec2(vUv.x - 2.0 * h, vUv.y)) * 0.12245;
    sum += texture(tDiffuse, vec2(vUv.x - 1.0 * h, vUv.y)) * 0.1531;
    sum += texture(tDiffuse, vec2(vUv.x,            vUv.y)) * 0.1633;
    sum += texture(tDiffuse, vec2(vUv.x + 1.0 * h, vUv.y)) * 0.1531;
    sum += texture(tDiffuse, vec2(vUv.x + 2.0 * h, vUv.y)) * 0.12245;
    sum += texture(tDiffuse, vec2(vUv.x + 3.0 * h, vUv.y)) * 0.0918;
    sum += texture(tDiffuse, vec2(vUv.x + 4.0 * h, vUv.y)) * 0.051;

    fragColor = sum;
}
