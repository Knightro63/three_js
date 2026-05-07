#version 460 core

// Binding indices should be adjusted based on your final pipeline layout
layout(set = 0, binding = 2) uniform sampler2D alphaMap;

// Input from vertex shader (location must match vertex output)
layout(location = 1) in vec2 vAlphaMapUv;

/**
 * Converts: diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
 * Note: GLSL 4.60 uses 'texture()' instead of 'texture2D()'
 */
void applyAlphaMap(inout vec4 diffuseColor) {
    diffuseColor.a *= texture(alphaMap, vAlphaMapUv).g;
}
