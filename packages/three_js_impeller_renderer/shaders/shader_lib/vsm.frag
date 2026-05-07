#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec2 resolution;
    float radius;
    int samples;          // SPIR-V replacement for VSM_SAMPLES
    bool isHorizontal;    // SPIR-V replacement for #ifdef HORIZONTAL_PASS
};

// Binding 60: shadow_pass (Reusing map slot for post-processing source)
layout(binding = 60) uniform sampler2D shadow_pass;

// Final Output
layout(location = 54) out vec4 pc_fragColor;

// Helper: unpackRGBAToDepth
float unpackRGBAToDepth(vec4 rgba) {
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

// Helper: pack2HalfToRGBA (Simplified VSM variance packing)
vec4 pack2HalfToRGBA(vec2 v) {
    return vec4(v.x, v.y, 0.0, 1.0); 
}

void main() {
    float fSamples = float(samples);
    float mean = 0.0;
    float squared_mean = 0.0;
    
    float uvStride = fSamples <= 1.0 ? 0.0 : 2.0 / (fSamples - 1.0);
    float uvStart = fSamples <= 1.0 ? 0.0 : -1.0;

    for (int i = 0; i < samples; i++) {
        float uvOffset = uvStart + float(i) * uvStride;
        vec2 samplePos;
        
        if (isHorizontal) {
            samplePos = (gl_FragCoord.xy + vec2(uvOffset, 0.0) * radius) / resolution;
        } else {
            samplePos = (gl_FragCoord.xy + vec2(0.0, uvOffset) * radius) / resolution;
        }

        vec4 texel = texture(shadow_pass, samplePos);
        float depth = unpackRGBAToDepth(texel);
        
        mean += depth;
        squared_mean += depth * depth;
    }

    mean /= fSamples;
    squared_mean /= fSamples;
    float std_dev = sqrt(max(0.0, squared_mean - mean * mean));

    pc_fragColor = pack2HalfToRGBA(vec2(mean, std_dev));
}
