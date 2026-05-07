#version 460 core

/**
 * Converts ditheringParsFragment logic.
 * Based on https://www.shadertoy.com/view/MslGR8
 * Note: Requires rand() from common.frag.
 */
vec3 dithering(vec3 color) {
    // Calculate grid position using the built-in screen-space coordinate
    float grid_position = rand(gl_FragCoord.xy);

    // Shift the individual colors differently
    vec3 dither_shift_RGB = vec3(0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0);

    // Modify shift according to grid position
    dither_shift_RGB = mix(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position);

    // Shift the color by dither_shift
    return color + dither_shift_RGB;
}
