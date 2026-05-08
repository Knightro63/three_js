#version 460 core

/**
 * Stage: Vertex
 * Purpose: Transforms position to world-space direction for equirectangular lookup.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"

// 2. VARYINGS (Outputs)
// Location 10: vWorldPosition per Master List (Synced with Frag 10)
layout(location = 10) out vec3 vWorldPosition;

void main() {
    // transformDirection is provided by common.vert
    // It applies modelMatrix rotation to derive the world-space direction
    vWorldPosition = transformDirection(inPosition, modelMatrix);

    // 3. CORE GEOMETRY
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"
    
    // Note: Unlike Cube backgrounds, we don't force gl_Position.z = w here 
    // unless this is being used specifically as a background.
}
