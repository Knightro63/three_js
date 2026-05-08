
/**
 * Location 8: Interpolated color from the vertex shader.
 * We use vec4 to support both USE_COLOR (RGB) and USE_COLOR_ALPHA (RGBA).
 */
layout(location = 8) in vec4 vColor;

/**
 * Converts colorFragment logic.
 * Note: 'diffuseColor' is modified in-place.
 */
void applyVertexColor(inout vec4 diffuseColor, bool useAlpha) {
    if (useAlpha) {
        // USE_COLOR_ALPHA
        diffuseColor *= vColor;
    } else {
        // USE_COLOR
        diffuseColor.rgb *= vColor.rgb;
    }
}
