#version 460 core

/**
 * Stage: Fragment
 * Purpose: Renders dashed lines by discarding fragments based on cumulative distance.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/color_pars.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"
#include "../shader_chunk/fog_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
    float dashSize;
    float totalSize;
};

// Location 55: vLineDistance synced with Vertex 55 per Master List
layout(location = 55) in float vLineDistance;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    // Initialize base color
    vec4 diffuseColor = vec4( diffuse, opacity );

    // 2. DASH LOGIC
    // Discard fragment if it falls within the 'gap' part of the dash cycle
    if ( mod( vLineDistance, totalSize ) > dashSize ) {
        discard;
    }

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map.frag"
    #include "../shader_chunk/color.frag"

    // 3. LIGHTING & FINALIZE
    // Dashed lines are typically unlit (Basic/Lambert style)
    vec3 outgoingLight = diffuseColor.rgb;

    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"
    #include "../shader_chunk/premultiplied_alpha.frag"

    pc_fragColor = vec4( outgoingLight, diffuseColor.a );
}
