#version 460 core

/**
 * Stage: Fragment
 * Purpose: VSM Shadow blur/pre-filter pass. 
 * Calculates Mean and Standard Deviation for soft shadows.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    vec2 resolution;
    float radius;
    int vsmSamples;      // Replacement for VSM_SAMPLES
    bool isHorizontal;   // Replacement for HORIZONTAL_PASS
};

// Binding 58: shadow_pass (using t2D slot) per Master List
layout(set = 0, binding = 58) uniform sampler2D shadow_pass;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    float samples = float(vsmSamples);
    float mean = 0.0;
    float squared_mean = 0.0;
    
    // Calculate sampling offsets
    float uvStride = samples <= 1.0 ? 0.0 : 2.0 / (samples - 1.0);
    float uvStart = samples <= 1.0 ? 0.0 : -1.0;

    for (float i = 0.0; i < samples; i++) {
        float uvOffset = uvStart + i * uvStride;
        
        if (isHorizontal) {
            // Horizontal blur: reads already packed RGBA 2-half data
            vec2 distribution = unpackRGBATo2Half(texture(shadow_pass, (gl_FragCoord.xy + vec2(uvOffset, 0.0) * radius) / resolution));
            mean += distribution.x;
            // variance = E[x^2] - E[x]^2. We accumulate raw squared values here.
            squared_mean += (distribution.y * distribution.y + distribution.x * distribution.x);
        } else {
            // Vertical/Initial pass: reads raw packed RGBA depth
            float depth = unpackRGBAToDepth(texture(shadow_pass, (gl_FragCoord.xy + vec2(0.0, uvOffset) * radius) / resolution));
            mean += depth;
            squared_mean += depth * depth;
        }
    }

    mean = mean / samples;
    squared_mean = squared_mean / samples;
    
    // Variance/StdDev calculation
    float variance = max(0.0, squared_mean - mean * mean);
    float std_dev = sqrt(variance);

    // Pack into RGBA for the VSM shadow map
    pc_fragColor = pack2HalfToRGBA(vec2(mean, std_dev));
}
