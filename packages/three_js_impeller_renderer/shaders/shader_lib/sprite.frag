#version 460 core

/**
 * Stage: Fragment
 * Purpose: Master template for billboarding sprites.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"         // Binding 60
#include "../shader_chunk/alphamap_pars.frag"    // Binding 2
#include "../shader_chunk/alphatest_pars.frag"
#include "../shader_chunk/alpha_hash_pars.frag"
#include "../shader_chunk/fog_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
};

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec4 diffuseColor = vec4( diffuse, opacity );
    vec3 outgoingLight = vec3( 0.0 );

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    
    // Standard map sampling (Location 23)
    #include "../shader_chunk/map.frag"
    #include "../shader_chunk/alphamap.frag"
    #include "../shader_chunk/alphatest.frag"
    #include "../shader_chunk/alpha_hash_fragment.frag"

    outgoingLight = diffuseColor.rgb;

    // 2. FINALIZE & OUTPUT
    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"

    pc_fragColor = vec4( outgoingLight, diffuseColor.a );
}
