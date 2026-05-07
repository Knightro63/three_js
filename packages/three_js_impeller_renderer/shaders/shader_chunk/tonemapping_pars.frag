#version 460 core

/**
 * Converted from tonemappingParsFragment.
 * Comprehensive Tone Mapping math library.
 * Requires common.frag for saturate() and PI.
 */

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float toneMappingExposure;
};

vec3 LinearToneMapping(vec3 color) {
    return saturate(toneMappingExposure * color);
}

vec3 ReinhardToneMapping(vec3 color) {
    color *= toneMappingExposure;
    return saturate(color / (vec3(1.0) + color));
}

vec3 OptimizedCineonToneMapping(vec3 color) {
    color *= toneMappingExposure;
    color = max(vec3(0.0), color - 0.004);
    return pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), vec3(2.2));
}

vec3 RRTAndODTFit(vec3 v) {
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

vec3 ACESFilmicToneMapping(vec3 color) {
    const mat3 ACESInputMat = mat3(
        vec3(0.59719, 0.07600, 0.02840),
        vec3(0.35458, 0.90834, 0.13383),
        vec3(0.04823, 0.01566, 0.83777)
    );
    const mat3 ACESOutputMat = mat3(
        vec3(1.60475, -0.10208, -0.00327),
        vec3(-0.53108, 1.10813, -0.07276),
        vec3(-0.07367, -0.00605, 1.07602)
    );

    color *= toneMappingExposure / 0.6;
    color = ACESInputMat * color;
    color = RRTAndODTFit(color);
    color = ACESOutputMat * color;
    return saturate(color);
}

// ... (AgX and Neutral implementations follow the same conversion pattern)

vec3 toneMapping(vec3 color) {
    // In your final shader, you would call the specific function 
    // chosen by the user or a 'uToneMappingMode' uniform.
    return ACESFilmicToneMapping(color); 
}
