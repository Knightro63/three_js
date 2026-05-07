#version 460 core

// Binding 4: Primary Diffuse Map (Standard Base Color)
layout(set = 0, binding = 4) uniform sampler2D map;

// Location 23: UV coordinates for the Diffuse Map (Sequential after vFragDepth at 22)
layout(location = 23) in vec2 vMapUv;

/**
 * Converts mapFragment logic.
 * Note: decodeVideo determines if we use the inline sRGB decode for video textures.
 */
void applyDiffuseMap(inout vec4 diffuseColor, bool decodeVideo) {
    vec4 sampledDiffuseColor = texture(map, vMapUv);

    if (decodeVideo) {
        // Inline sRGB decode logic
        sampledDiffuseColor = vec4(mix(
            pow(sampledDiffuseColor.rgb * 0.9478672986 + vec3(0.0521327014), vec3(2.4)),
            sampledDiffuseColor.rgb * 0.0773993808,
            vec3(lessThanEqual(sampledDiffuseColor.rgb, vec3(0.04045)))
        ), sampledDiffuseColor.w);
    }

    diffuseColor *= sampledDiffuseColor;
}
