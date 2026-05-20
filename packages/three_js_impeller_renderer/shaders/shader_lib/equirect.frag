#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"

// 2. UNIFORMS BLOCK
// Keeping this block identical to your vertex setup preserves unified indexing
uniform ObjectUniforms {
    mat4 modelMatrix;       // Vertex stage memory overhead (Indices 0 through 15)
};

// 3. TEXTURE SAMPLERS
uniform sampler2D tEquirect; // Sampler Index 0

// 4. PIPELINE INPUTS (Implicit varying matching)
// This matches your vertex shader 'out vec3 vWorldDirection;' variable name exactly.
in vec3 vWorldDirection;

// 5. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec3 direction = normalize(vWorldDirection);
    
    // equirectUv is provided directly by the common.frag / equirect chunks under the hood
    vec2 sampleUV = equirectUv(direction);
    
    // Modern GLSL handles standard 'texture' lookups dynamically based on type definitions
    fragColor = texture(tEquirect, sampleUV);

    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
}
