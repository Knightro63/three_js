#version 460 core

/**
 * Stage: Fragment
 * Purpose: Master template for point cloud/particle materials.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/color_pars.frag"
#include "../shader_chunk/map_particle_pars.frag"
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
    
    // Uses gl_PointCoord for texture sampling on the point quad
    #include "../shader_chunk/map_particle.frag"
    
    #include "../shader_chunk/color.frag"
    #include "../shader_chunk/alphatest.frag"
    #include "../shader_chunk/alpha_hash_fragment.frag"

    outgoingLight = diffuseColor.rgb;

    // 2. FINALIZE & OUTPUT
    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"
    #include "../shader_chunk/premultiplied_alpha.frag"

    pc_fragColor = vec4( outgoingLight, diffuseColor.a );
}
