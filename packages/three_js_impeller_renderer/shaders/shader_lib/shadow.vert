#version 460 core

/**
 * Stage: Vertex
 * Purpose: Master template for Shadow Catcher materials.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars.vert"
#include "../shader_chunk/fog_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/skinning_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/shadowmap_pars.vert" // Reserved blocks 29, 33, 37

void main() {
    // 2. SETUP & ANIMATION
    #include "../shader_chunk/batching.vert"
    #include "../shader_chunk/beginnormal.vert"
    #include "../shader_chunk/morphinstance.vert"
    #include "../shader_chunk/morphnormal.vert"
    #include "../shader_chunk/skinbase.vert"
    #include "../shader_chunk/skinnormal.vert"
    #include "../shader_chunk/defaultnormal.vert"

    // 3. GEOMETRY DEFORMATION
    #include "../shader_chunk/begin.vert"
    #include "../shader_chunk/morphtarget.vert"
    #include "../shader_chunk/skinning.vert"

    // 4. PROJECTION
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"

    // 5. VARYINGS FOR SHADOWS & FOG
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/shadowmap.vert" // Populates blocks 29, 33, 37
    #include "../shader_chunk/fog.vert"
}
