#version 460 core

/**
 * Stage: Vertex
 * Purpose: Cubemap/Skybox geometry transformation.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"

// 2. VARYINGS (Outputs)
// Location 10: vWorldPosition per Master List (Synced with Frag 10)
layout(location = 10) out vec3 vWorldPosition;

void main() {
    // transformDirection is provided by common.vert
    // It applies modelMatrix rotation but ignores translation
    vWorldPosition = transformDirection(inPosition, modelMatrix);

    // 3. CORE GEOMETRY
    #include "../shader_chunk/begin.vert"
    #include "../shader_chunk/project.vert"

    // 4. DEPTH TRICK
    // Set z to w so that the background is always at the far clipping plane
    gl_Position.z = gl_Position.w;
}
