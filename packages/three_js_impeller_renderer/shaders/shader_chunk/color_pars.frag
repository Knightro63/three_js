#version 460 core

/**
 * Location 8: Interpolated color from the vertex shader.
 * We use vec4 as the standard to support both RGB and RGBA meshes.
 */
layout(location = 8) in vec4 vColor;
