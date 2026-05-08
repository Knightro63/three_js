
// Vertex attribute for color (Location 4 follows batchId at 3)
layout(location = 4) in vec4 color;

// Instance attribute for color (if using instancing)
layout(location = 5) in vec3 instanceColor;

// Output to Fragment Shader (Matches Frag Location 8)
layout(location = 8) out vec4 vColor;

/**
 * Converts colorVertex logic.
 * Handles standard vertex color and instance color blending.
 */
void applyVertexColor(bool useColor, bool useInstancingColor) {
    // Initialize vColor (defaults to white/1.0)
    vColor = vec4(1.0);

    if (useColor) {
        vColor *= color;
    }

    if (useInstancingColor) {
        vColor.xyz *= instanceColor;
    }
}
