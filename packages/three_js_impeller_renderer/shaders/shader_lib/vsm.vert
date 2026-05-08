#version 460 core

/**
 * Stage: Vertex
 * Purpose: Pass-through vertex shader for VSM shadow pre-filtering.
 */

// Location 0: Mesh positions per Master List
layout(location = 0) in vec3 inPosition;

void main() {
    // Directly output position as clip-space coordinates
    // Used for a fullscreen quad [-1, 1] range
    gl_Position = vec4(inPosition, 1.0);
}
