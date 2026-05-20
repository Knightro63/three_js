#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/packing.frag"

// 2. UNIFORMS BLOCKS
// Sequential memory block stacking immediately behind your 32-slot vertex matrices.
uniform MaterialUniforms {
    float radius;            // Float Index 32
    float vsmSamples;        // Float Index 33 (Replaces compile-time VSM_SAMPLES macro)
    bool isHorizontalPass;   // Float Index 34 (Replaces compile-time HORIZONTAL_PASS macro)
};

// 3. TEXTURE SAMPLERS
uniform sampler2D shadow_pass; // Sampler Index 0 (De-coupled from flat float array)

// 4. PIPELINE INPUTS (Normalized coordinates matching texture space [0.0 - 1.0])
in vec2 vUv;

// 5. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    float mean = 0.0;
    float squared_mean = 0.0;
    
    // Protection fallback check to prevent zero division loop lockouts
    float samplesCount = max(vsmSamples, 1.0);
    float uvStride = samplesCount <= 1.0 ? 0.0 : 2.0 / (samplesCount - 1.0);
    float uvStart = samplesCount <= 1.0 ? 0.0 : -1.0;

    for (float i = 0.0; i < 64.0; i++) { // Set a clean fixed max-loop ceiling for AOT compiler bounds
        if (i >= samplesCount) break;

        float uvOffset = uvStart + i * uvStride;
        
        if (isHorizontalPass) {
            // Directly utilize normalized UV steps instead of dividing gl_FragCoord by resolution
            vec2 sampleCoord = vUv + vec2(uvOffset * radius, 0.0);
            vec2 distribution = unpackRGBATo2Half(texture(shadow_pass, sampleCoord));
            
            mean += distribution.x;
            squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;
        } else {
            vec2 sampleCoord = vUv + vec2(0.0, uvOffset * radius);
            float depth = unpackRGBAToDepth(texture(shadow_pass, sampleCoord));
            
            mean += depth;
            squared_mean += depth * depth;
        }
    }

    mean = mean / samplesCount;
    squared_mean = squared_mean / samplesCount;
    
    float std_dev = sqrt(max(squared_mean - mean * mean, 0.0)); // Prevent negative square root crashes
    
    // pack2HalfToRGBA is loaded out of packing.frag under the hood
    fragColor = pack2HalfToRGBA(vec2(mean, std_dev));
}
