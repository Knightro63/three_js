#version 460 core

/**
 * Stage: Vertex
 * Purpose: Pass-through for post-processing quads.
 */

#include "../shader_chunk/common.vert"

// Location 53: vUv per Master List (Synced with Frag 53)
layout(location = 53) out vec2 vUv;

void main() {
    // Pass raw UV attribute (Location 29) to varying
    vUv = inUv;

    // Standard projection for screen-space quads
    gl_Position = projectionMatrix * modelViewMatrix * vec4(inPosition, 1.0);
}
