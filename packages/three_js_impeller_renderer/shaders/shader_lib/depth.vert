#version 460 core

// 1. INCLUDE DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/displacementmap_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/skinning_pars.vert"
#include "../shader_chunk/logdepthbuf_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

// Location 56: High precision ZW synced with Frag 56
layout(location = 56) out vec2 vHighPrecisionZW;

void main() {
    // 2. INITIALIZATION & SETUP
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/batching.vert"
    #include "../shader_chunk/skinbase.vert"
    #include "../shader_chunk/morphinstance.vert"

    // 3. NORMAL PROCESSING (Required for Displacement Mapping)
    // Only executed if Displacement Mapping is active
    #include "../shader_chunk/beginnormal.vert"
    #include "../shader_chunk/morphnormal.vert"
    #include "../shader_chunk/skinnormal.vert"

    // 4. GEOMETRY TRANSFORMATION
    #include "../shader_chunk/begin.vert"
    #include "../shader_chunk/morphtarget.vert"
    #include "../shader_chunk/skinning.vert"
    #include "../shader_chunk/displacementmap.vert"
    #include "../shader_chunk/project_vertex.vert"

    // 5. DEPTH & CLIPPING
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"

    // High precision equivalent of gl_FragCoord.z
    vHighPrecisionZW = gl_Position.zw;
}
