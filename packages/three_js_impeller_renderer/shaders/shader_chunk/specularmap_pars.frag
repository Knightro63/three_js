#version 460 core

/**
 * Binding 54: Dedicated sampler for the Specular map.
 * Used to scale specular intensity in Phong/Lambert materials.
 */
layout(set = 0, binding = 54) uniform sampler2D specularMap;
