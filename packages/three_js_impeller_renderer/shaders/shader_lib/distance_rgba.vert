#version 460 core

#define DISTANCE

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars.vert"
#include "../shader_chunk/uv_pars.vert"
#include "../shader_chunk/displacementmap_pars.vert"
#include "../shader_chunk/morphtarget_pars.vert"
#include "../shader_chunk/skinning_pars.vert"
#include "../shader_chunk/clipping_planes_pars.vert"

// Location 10: vWorldPosition synced with Frag 10 per Master List
layout(location = 10) out vec3 vWorldPosition;

void main() {
    // 2. SETUP & BATCHING
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/batching.vert"
    #include "../shader_chunk/skinbase.vert"
    #include "../shader_chunk/morphinstance.vert"

    // 3. NORMAL PROCESSING (Required for Displacement Mapping)
    #include "../shader_chunk/beginnormal.vert"
    #include "../shader_chunk/morphnormal.vert"
    #include "../shader_chunk/skinnormal.vert"

    // 4. GEOMETRY DEFORMATION
    #include "../shader_chunk/begin.vert"
    #include "../shader_chunk/morphtarget.vert"
    #include "../shader_chunk/skinning.vert"
    #include "../shader_chunk/displacementmap.vert"

    // 5. PROJECTION & WORLD POSITION
    #include "../shader_chunk/project_vertex.vert"
    
    // worldpos_vertex.vert populates the 'worldPosition' variable
    #include "../shader_chunk/worldpos_vertex.vert"
    
    #include "../shader_chunk/clipping_planes.vert"

    // Pass world-space position to fragment shader for distance calculation
    vWorldPosition = worldPosition.xyz;
}
