#version 460 core

/**
 * Stage: Vertex
 * Purpose: Prepares geometry and distance data for dashed lines.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/color_pars.vert"
#include "../shader_chunk/fog_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

// 2. INPUTS & OUTPUTS
// Location 32: lineDistance attribute from mesh per Master List
layout(location = 32) in float lineDistance;

// Location 55: vLineDistance synced with Frag 55 per Master List
layout(location = 55) out float vLineDistance;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    float scale; // Scaling factor for the dash pattern
};

void main() {
    // Calculate the scaled distance along the line
    vLineDistance = scale * lineDistance;

    // 3. SETUP VARYINGS
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphinstance.vert"
    #include "../shader_chunk/morphcolor.vert"

    // 4. CORE GEOMETRY
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget.vert"
    #include "../shader_chunk/project_vertex.vert"

    // 5. DEPTH & CLIPPING
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
