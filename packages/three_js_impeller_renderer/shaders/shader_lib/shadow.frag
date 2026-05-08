#version 460 core

/**
 * Stage: Fragment
 * Purpose: Master template for "Shadow Catcher" materials.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/fog_pars.frag"
#include "../shader_chunk/bsdfs.frag"
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/shadowmap_pars.frag"   // Blocks 29, 33, 37
#include "../shader_chunk/shadowmask_pars.frag"  // Provides getShadowMask()

layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 color;
    float opacity;
};

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/logdepthbuf_fragment.frag"

    /**
     * The shadow mask returns 1.0 (no shadow) to 0.0 (full shadow).
     * We invert it (1.0 - mask) so that shadowed areas become opaque.
     */
    float shadowAlpha = opacity * (1.0 - getShadowMask());

    // outgoingLight is used by tonemapping and fog chunks
    vec3 outgoingLight = color;

    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"

    pc_fragColor = vec4(outgoingLight, shadowAlpha);
}
