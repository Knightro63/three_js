#version 460 core

/**
 * Location 8: Output to Fragment Shader (Vertex Stage).
 */
layout(location = 8) out float vFogDepth;

/**
 * Converts: vFogDepth = - mvPosition.z;
 * Note: mvPosition is the vertex position in Model-View space.
 */
void applyFogVertex(vec4 mvPosition) {
    vFogDepth = -mvPosition.z;
}
