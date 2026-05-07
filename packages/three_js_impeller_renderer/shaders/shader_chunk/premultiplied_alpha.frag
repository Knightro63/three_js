#version 460 core

// Final output color (Location 0)
layout(location = 0) out vec4 fragColor;

/**
 * Converts premultipliedAlphaFragment logic.
 * Multiplies the RGB channels by the Alpha channel.
 * Required when using BlendState with:
 *   - sourceColorBlendFactor: gpu.BlendFactor.one
 *   - destinationColorBlendFactor: gpu.BlendFactor.oneMinusSourceAlpha
 */
void applyPremultipliedAlpha() {
    fragColor.rgb *= fragColor.a;
}
