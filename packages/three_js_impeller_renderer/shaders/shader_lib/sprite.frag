#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/uv_pars_fragment.frag"
#include "../shader_chunk/map_pars_fragment.frag"
#include "../shader_chunk/alphamap_pars_fragment.frag"
#include "../shader_chunk/alphatest_pars_fragment.frag"
#include "../shader_chunk/alphahash_pars_fragment.frag"
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Keeping this block aligned to follow your 32-slot base vertex projection matrix sequence.
uniform MaterialUniforms {
    vec3 diffuse;      // Float Indices 32, 33, 34 (Base flat texture color)
    float opacity;     // Float Index 35           (Material transparency)
};

// 3. PIPELINE INPUTS (Interpolated variables passed from vertex stage)
in vec2 vUv;

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec3 outgoingLight = vec3(0.0);

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    
    // Note: map_fragment.frag handles texture sampling overlays using vUv mapping registers
    #include "../shader_chunk/map_fragment.frag"
    #include "../shader_chunk/alphamap_fragment.frag"
    #include "../shader_chunk/alphatest_fragment.frag"
    #include "../shader_chunk/alphahash_fragment.frag"

    outgoingLight = diffuseColor.rgb;

    #include "../shader_chunk/opaque_fragment.frag"
    #include "../shader_chunk/tonemapping_fragment.frag"
    #include "../shader_chunk/colorspace_fragment.frag"
    #include "../shader_chunk/fog_fragment.frag"

    // Route the final flat pixel color vector directly to the frame buffer target
    fragColor = vec4(outgoingLight, diffuseColor.a);
}
