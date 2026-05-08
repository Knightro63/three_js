
// Final output color (Location 0 per Master List)
layout(location = 0) out vec4 fragColor;

/**
 * Converts opaqueFragment logic.
 * Finalizes diffuseColor.a and writes the final vec4 to the framebuffer.
 */
void finalizeOpaquePass(
    vec3 outgoingLight, 
    inout vec4 diffuseColor, 
    float transmissionAlpha, 
    bool isOpaque, 
    bool useTransmission
) {
    if (isOpaque) {
        diffuseColor.a = 1.0;
    }

    if (useTransmission) {
        diffuseColor.a *= transmissionAlpha;
    }

    // gl_FragColor -> fragColor in 4.60
    fragColor = vec4(outgoingLight, diffuseColor.a);
}
