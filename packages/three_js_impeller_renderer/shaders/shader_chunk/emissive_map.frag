
// Binding 12: Dedicated sampler for the Emissive map
layout(set = 0, binding = 12) uniform sampler2D emissiveMap;

// Location 9: UV coordinates for the Emissive Map
layout(location = 9) in vec2 vEmissiveMapUv;

/**
 * Converts emissivemapFragment logic.
 * Multiplies the totalEmissiveRadiance by the sampled map color.
 */
void applyEmissiveMap(inout vec3 totalEmissiveRadiance) {
    // texture2D -> texture in 4.60
    vec4 emissiveColor = texture(emissiveMap, vEmissiveMapUv);
    
    totalEmissiveRadiance *= emissiveColor.rgb;
}
