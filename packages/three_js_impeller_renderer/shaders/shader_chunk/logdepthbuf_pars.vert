#version 460 core

/**
 * Location 9: Perspective toggle (0.0 for Ortho, 1.0 for Perspective).
 * Sequential after vFogDepth (8).
 */
layout(location = 9) out float vIsPerspective;

/**
 * Location 10: High-precision depth value passed to fragment shader.
 */
layout(location = 10) out float vFragDepth;
