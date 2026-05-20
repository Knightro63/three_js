#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/uv_pars_fragment.frag"
#include "../shader_chunk/normal_pars_fragment.frag"
#include "../shader_chunk/bumpmap_pars_fragment.frag"
#include "../shader_chunk/normalmap_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Keeping this block aligned to follow your 32-slot base vertex matrix sequence.
uniform MaterialUniforms {
    float opacity;       // Float Index 32
    bool isOpaqueMaterial; // Float Index 33 (Converted from compile-time OPAQUE macro)
};

// 3. PIPELINE INPUTS (Interpolated variables from vertex stage)
in vec3 vViewPosition;
in vec3 vNormal; // Evaluated and updated inside normal_fragment_begin.frag

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 diffuseColor = vec4(0.0, 0.0, 0.0, opacity);

    #include "../shader_chunk/clipping_planes_fragment.frag"
    #include "../shader_chunk/logdepthbuf_fragment.frag"
    
    // Evaluate geometry normals and apply active bump maps or normal maps
    // These chunks manipulate and normalize the local variable 'normal'
    #include "../shader_chunk/normal_fragment_begin.frag"
    #include "../shader_chunk/normal_fragment_maps.frag"

    // Pack the evaluated [-1, 1] normal vector smoothly into [0, 1] RGB space
    // 'packNormalToRGB' is provided directly via the packing.frag chunk
    vec4 finalColor = vec4(packNormalToRGB(normal), diffuseColor.a);

    // Converted runtime branch instead of compile-time #ifdef OPAQUE macro
    if (isOpaqueMaterial) {
        finalColor.a = 1.0;
    }

    // Route the final normal map color vector directly to the frame buffer target
    fragColor = finalColor;
}
