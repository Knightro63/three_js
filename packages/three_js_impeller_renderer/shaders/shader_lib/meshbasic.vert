#version 460 core

/**
 * Stage: Vertex
 * Purpose: Master template for unlit materials (Basic).
 */

// 1. INCLUDE DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/envmap_pars.vert"
#include "../shader_chunk/color_pars.vert"
#include "../shader_chunk/fog_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/skinning_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

void main() {
    // 2. UV & COLOR SETUP
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    
    // 3. ANIMATION SETUP
    #include "../shader_chunk/morphinstance.vert"
    #include "../shader_chunk/morphcolor.vert"
    #include "../shader_chunk/batching.vert"

    // 4. NORMAL PROCESSING
    // Required even for Basic materials if using EnvMaps or Skinning
    // Toggles handled by uniforms inside the chunks
    #include "../shader_chunk/beginnormal.vert"
    #include "../shader_chunk/morphnormal.vert"
    #include "../shader_chunk/skinbase.vert"
    #include "../shader_chunk/skinnormal.vert"
    #include "../shader_chunk/defaultnormal.vert"

    // 5. CORE GEOMETRY
    #include "../shader_chunk/begin.vert"
    #include "../shader_chunk/morphtarget.vert"
    #include "../shader_chunk/skinning.vert"
    #include "../shader_chunk/project_vertex.vert"

    // 6. DEPTH & CLIPPING
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"

    // 7. VARYINGS FOR FRAGMENT
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/envmap_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
