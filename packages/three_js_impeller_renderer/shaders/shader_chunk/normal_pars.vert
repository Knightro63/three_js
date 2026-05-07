#version 460 core

/**
 * Stage: Vertex
 * Locations 24, 25, 26: Outputting the basis for Fragment TBN.
 */
layout(location = 24) out vec3 vNormal;
layout(location = 25) out vec3 vTangent;
layout(location = 26) out vec3 vBitangent;
