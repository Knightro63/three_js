
// Binding 16: Dedicated sampler for the Light Map
layout(set = 0, binding = 16) uniform sampler2D lightMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float lightMapIntensity;
};

/**
 * Location 2: Secondary UV set.
 * In your master list, Location 2 is used for AO/Secondary maps (vUv2).
 */
layout(location = 2) in vec2 vUv2;

/**
 * Converts lightmapFragment logic.
 * Adds sampled irradiance to the indirectDiffuse component.
 */
void applyLightMap(inout vec3 indirectDiffuse) {
    // texture2D -> texture in 4.60
    vec4 lightMapTexel = texture(lightMap, vUv2);
    vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
    
    indirectDiffuse += lightMapIrradiance;
}
