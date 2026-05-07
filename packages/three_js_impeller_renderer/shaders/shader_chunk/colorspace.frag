#version 460 core

// Your main fragment output
layout(location = 0) out vec4 fragColor;

/**
 * Converts: gl_FragColor = linearToOutputTexel( gl_FragColor );
 * Note: linearToOutputTexel must be defined in your common or color_utils library.
 */
void applyColorSpaceConversion() {
    fragColor = linearToOutputTexel(fragColor);
}
