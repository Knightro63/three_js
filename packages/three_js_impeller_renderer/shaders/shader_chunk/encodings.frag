
// Final output color (Location 0 per Master List)
layout(location = 0) out vec4 fragColor;

/**
 * Converts: gl_FragColor = linearToOutputTexel( gl_FragColor );
 * Note: linearToOutputTexel() is typically defined in colorspace_utils.frag.
 */
void applyEncodings() {
    fragColor = linearToOutputTexel(fragColor);
}
