#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/bsdfs.frag"
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/shadowmap_pars_fragment.frag"
#include "../shader_chunk/shadowmask_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Stacking this directly behind your 32-slot base vertex projection matrix sequence.
uniform MaterialUniforms {
    vec3 color;      // Float Indices 32, 33, 34 (Usually pure black: [0.0, 0.0, 0.0])
    float opacity;   // Float Index 35           (Maximum shadow transparency intensity)
};

// 3. PIPELINE INPUTS (Interpolated layout space values from the vertex stage)
in vec3 vNormal;
in vec2 vUv;

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    #include "../shader_chunk/logdepthbuf_fragment.frag"

    // The getShadowMask() calculation function is pulled directly from shadowmask_pars_fragment.frag
    // It returns 1.0 for full shadow (completely unlit) and 0.0 for full exposure (light completely hits mesh)
    float shadowIntensity = 1.0 - getShadowMask();
    vec4 diffuseColor = vec4(color, opacity * shadowIntensity);

    // Run core color space conversion chunks over the calculated transparent pixels
    #include "../shader_chunk/tonemapping_fragment.frag"
    #include "../shader_chunk/colorspace_fragment.frag"
    #include "../shader_chunk/fog_fragment.frag"

    // Route the shadow matrix overlay straight to the screen frame buffer layout
    fragColor = diffuseColor;
}
