#version 460 core

/**
 * Converts: LinearToLinear (Identity)
 */
vec4 LinearToLinear(in vec4 value) {
    return value;
}

/**
 * Converts: LinearTosRGB (OETF conversion)
 * Note: uses bvec3 comparison for GLSL 4.60 compatibility.
 */
vec4 LinearTosRGB(in vec4 value) {
    // lessThanEqual returns a bvec3; wrapping in vec3() converts to 0.0 or 1.0 weights
    return vec4(mix(
        pow(value.rgb, vec3(0.41666)) * 1.055 - vec3(0.055),
        value.rgb * 12.92,
        vec3(lessThanEqual(value.rgb, vec3(0.0031308)))
    ), value.a);
}
