#version 460 core

// Final output color (Location 0 per Master List)
layout(location = 0) out vec4 fragColor;

/**
 * Converts: gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
 * Note: toneMapping() must be defined in your tonemapping_pars file.
 */
void applyToneMapping() {
    fragColor.rgb = toneMapping(fragColor.rgb);
}
