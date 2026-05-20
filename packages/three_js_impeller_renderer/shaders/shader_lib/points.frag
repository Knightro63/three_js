#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/color_pars_fragment.frag"
#include "../shader_chunk/map_particle_pars_fragment.frag"
#include "../shader_chunk/alphatest_pars_fragment.frag"
#include "../shader_chunk/alphahash_pars_fragment.frag"
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Aligned to follow your 32-slot base vertex projection matrix sequence.
uniform MaterialUniforms {
    vec3 diffuse;      // Float Indices 32, 33, 34 (Particle base color)
    float opacity;     // Float Index 35           (Particle transparency)
};

// 3. PIPELINE INPUTS (Interpolated variables from the vertex stage)
in vec3 vColor;        // Populated if vertex colors are enabled
in vec2 vUv;           // Mapped automatically from gl_PointCoord in particle chunks

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec3 outgoingLight = vec3(0.0);

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    
    // Note: map_particle_fragment.frag handles texture sampling using gl_PointCoord / vUv
    #include "../shader_chunk/map_particle_fragment.frag"
    #include "../shader_chunk/color_fragment.frag"
    #include "../shader_chunk/alphatest_fragment.frag"
    #include "../shader_chunk/alphahash_fragment.frag"

    outgoingLight = diffuseColor.rgb;

    #include "../shader_chunk/opaque_fragment.frag"
    #include "../shader_chunk/tonemapping_fragment.frag"
    #include "../shader_chunk/colorspace_fragment.frag"
    #include "../shader_chunk/fog_fragment.frag"
    #include "../shader_chunk/premultiplied_alpha_fragment.frag"

    // Route the final evaluated particle pixel directly to the frame buffer target
    fragColor = vec4(outgoingLight, diffuseColor.a);
}
