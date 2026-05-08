#version 460 core

/**
 * Stage: Vertex
 * Purpose: Master template for Normal materials.
 */

#define NORMAL

// 1. INCLUDE DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/displacementmap_pars.vert"
#include "../shader_chunk/normal_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/skinning_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

// Location 13: vViewPosition synced with Frag 13
layout(location = 13) out vec3 vViewPosition;

void main() {
    // 2. SETUP & BATCHING
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/batching.vert"
    #include "../shader_chunk/morphinstance.vert"

    // 3. NORMAL PROCESSING
    // Essential for visualizing the basis vectors
    #include "../shader_chunk/beginnormal.vert"
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

    // 5. PROJECTION
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"

    // 6. VIEW POSITION
    // Required for Bump/Normal mapping in the fragment stage
    vViewPosition = -mvPosition.xyz;
}
