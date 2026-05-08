#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"

// Location 10: vWorldPosition/Direction per Master List
layout(location = 10) out vec3 vWorldPosition;

void main() {
    // 2. CALCULATE DIRECTION
    // transformDirection is provided by common.vert
    vWorldPosition = transformDirection(inPosition, modelMatrix);

    // 3. CORE GEOMETRY
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"

    // 4. DEPTH TRICK
    // Set z to w so that the background is always at the far clipping plane (1.0 in NDC)
    gl_Position.z = gl_Position.w;
}
