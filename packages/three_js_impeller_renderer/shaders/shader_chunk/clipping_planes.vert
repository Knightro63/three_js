
/**
 * Location 7: Output to Fragment Shader
 */
layout(location = 7) out vec3 vClipPosition;

/**
 * Converts: vClipPosition = - mvPosition.xyz;
 * Note: mvPosition is the vertex position in Model-View space.
 */
void applyClippingVertex(vec4 mvPosition) {
    vClipPosition = -mvPosition.xyz;
}
