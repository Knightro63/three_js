
// Binding 0: Standard Frame Uniforms
layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 projectionMatrix;
    mat4 modelViewMatrix;
};

/**
 * Converts projectVertex logic.
 * Note: 'transformed' is the local position after morphing/skinning.
 * Returns mvPosition for use in lighting/fog/clipping snippets.
 */
vec4 projectVertex(vec3 transformed, mat4 batchingMatrix, mat4 instanceMatrix, bool useBatching, bool useInstancing) {
    vec4 mvPosition = vec4(transformed, 1.0);

    if (useBatching) {
        mvPosition = batchingMatrix * mvPosition;
    }

    if (useInstancing) {
        mvPosition = instanceMatrix * mvPosition;
    }

    // Transform to View Space
    mvPosition = modelViewMatrix * mvPosition;

    // Final Clip Space position
    gl_Position = projectionMatrix * mvPosition;

    return mvPosition;
}
