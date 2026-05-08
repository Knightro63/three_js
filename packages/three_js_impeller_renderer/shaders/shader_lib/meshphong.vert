#version 460 core

/**
 * Stage: Vertex
 * Purpose: Master template for specular-inclusive materials (Phong).
 */

#define PHONG

// 1. INCLUDE DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/displacementmap_pars.vert"
#include "../shader_chunk/envmap_pars.vert"
#include "../shader_chunk/color_pars.vert"
#include "../shader_chunk/fog_pars.vert"
#include "../shader_chunk/normal_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/skinning_pars.vert"
#include "../shader_chunk/shadowmap_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

// Location 13: vViewPosition synced with Frag 13 per Master List
layout(location = 13) out vec3 vViewPosition;

void main() {
    // 2. SETUP & BATCHING
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphcolor.vert"
    #include "../shader_chunk/batching.vert"

    // 3. NORMAL PROCESSING
    #include "../shader_chunk/beginnormal.vert"
    #include "../shader_chunk/morphinstance.vert"
    #include "../shader_chunk/morphnormal.vert"
    #include "../shader_chunk/skinbase.vert"
    #include "../shader_chunk/skinnormal.vert"
    #include "../shader_chunk/defaultnormal.vert"
    #include "../shader_chunk/normal.vert"

    // 4. GEOMETRY DEFORMATION
    #include "../shader_chunk/begin.vert"
    #include "../shader_chunk/morphtarget.vert"
    #include "../shader_chunk/skinning.vert"
    #include "../shader_chunk/displacementmap.vert"

    // 5. PROJECTION & DEPTH
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"

    // View-space position for fragment-side lighting
    vViewPosition = -mvPosition.xyz;

    // 6. VARYINGS FOR FRAGMENT
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/envmap_vertex.vert"
    #include "../shader_chunk/shadowmap.vert"
    #include "../shader_chunk/fog.vert"
}
