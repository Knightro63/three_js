
// Final output color
layout(location = 0) out vec4 fragColor;

/**
 * Converts: gl_FragColor.rgb = dithering( gl_FragColor.rgb );
 * Note: dithering() must be defined in your dithering_pars file.
 */
void applyDithering() {
    fragColor.rgb = dithering(fragColor.rgb);
}
