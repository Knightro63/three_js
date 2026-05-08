#version 460 core

/**
 * Stage: Vertex
 * Purpose: Master template for PBR materials (Physical/Standard).
 */

#define STANDARD

// 1. INCLUDE DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/displacementmap_pars.vert"
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

// Location 6/10: World position for reflections/transmission
layout(location = 6) out vec3 vWorldPosition;

void main() {
    // 2. SETUP & BATCHING
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphinstance.vert"
    #include "../shader_chunk/morphcolor.vert"
    #include "../shader_chunk/batching.vert"

    // 3. NORMAL PROCESSING (Critical for PBR TBN & Reflections)
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

    // 5. PROJECTION & DEPTH
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes.vert"

    // Set view position for PBR lighting (GGX/Specular)
    vViewPosition = -mvPosition.xyz;

    // 6. VARYINGS FOR FRAGMENT (Shadows, Environment, Fog)
    #include "../shader_chunk/worldpos_vertex.vert" // Populates 'worldPosition'
    #include "../shader_chunk/shadowmap.vert"
    #include "../shader_chunk/fog.vert"

    // Explicitly pass world position for Transmission/Refractions
    vWorldPosition = worldPosition.xyz;
}
