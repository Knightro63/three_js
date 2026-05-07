#version 460 core

/**
 * Stage: Vertex
 * Outputs: vWorldPosition to Frag Location 10 (per Master List).
 */
layout(location = 10) out vec3 vWorldPosition;

layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 modelMatrix;
};

/**
 * Converts worldposVertex logic.
 * Calculates worldPosition and populates the vWorldPosition varying.
 */
vec4 calculateWorldPosition(
    vec3 transformed, 
    mat4 batchingMatrix, 
    mat4 instanceMatrix, 
    bool useBatching, 
    bool useInstancing
) {
    vec4 worldPosition = vec4(transformed, 1.0);

    if (useBatching) {
        worldPosition = batchingMatrix * worldPosition;
    }

    if (useInstancing) {
        worldPosition = instanceMatrix * worldPosition;
    }

    // Apply the model transformation
    worldPosition = modelMatrix * worldPosition;

    // Populate varying for environment mapping/transmission/shadows
    vWorldPosition = worldPosition.xyz;

    return worldPosition;
}
