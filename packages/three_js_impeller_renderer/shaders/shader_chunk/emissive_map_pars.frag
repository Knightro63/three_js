#version 460 core

/**
 * Binding 12: Dedicated sampler for the Emissive map.
 * Used for self-illumination logic in the fragment shader.
 */
layout(set = 0, binding = 12) uniform sampler2D emissiveMap;
