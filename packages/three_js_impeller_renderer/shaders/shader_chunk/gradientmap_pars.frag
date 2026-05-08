
/**
 * Binding 13: Dedicated sampler for the Gradient Map.
 * Typically a small 1D or 2D texture defining the stepped lighting ramp.
 */
layout(set = 0, binding = 13) uniform sampler2D gradientMap;

/**
 * Converts getGradientIrradiance logic.
 * Samples the gradientMap based on the dot product of normal and light.
 */
vec3 getGradientIrradiance(vec3 normal, vec3 lightDirection, bool useGradientMap) {
    // dotNL will be from -1.0 to 1.0
    float dotNL = dot(normal, lightDirection);
    vec2 coord = vec2(dotNL * 0.5 + 0.5, 0.0);

    if (useGradientMap) {
        // texture2D -> texture in 4.60
        return vec3(texture(gradientMap, coord).r);
    } else {
        // Fallback procedural "Toon" look if no map is provided
        vec2 fw = fwidth(coord) * 0.5;
        return mix(vec3(0.7), vec3(1.0), smoothstep(0.7 - fw.x, 0.7 + fw.x, coord.x));
    }
}
