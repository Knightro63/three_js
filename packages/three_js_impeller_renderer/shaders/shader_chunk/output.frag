#version 460 core

// Final output color (Location 0)
layout(location = 0) out vec4 fragColor;

/**
 * Converts outputFragment logic.
 * Finalizes alpha with the transmission offset and writes to the framebuffer.
 */
void finalizeOutput(
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
        // Includes the +0.1 offset from Three.js PR #22425
        diffuseColor.a *= (transmissionAlpha + 0.1);
    }

    fragColor = vec4(outgoingLight, diffuseColor.a);
}
