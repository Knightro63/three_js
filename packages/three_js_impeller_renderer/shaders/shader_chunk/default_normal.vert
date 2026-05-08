
// Output to Fragment Shader (Location 3 per Master List)
layout(location = 3) out vec3 vNormal;

layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 viewMatrix;
    mat4 modelMatrix;
    mat3 normalMatrix; // Inverse transpose of ModelView
};

/**
 * Converts defaultnormalVertex logic.
 * Transforms normals/tangents while handling Batching and Instancing.
 */
void applyNormalTransform(
    vec3 objectNormal, 
    vec3 objectTangent, 
    mat4 batchingMatrix, 
    mat4 instanceMatrix,
    bool useBatching,
    bool useInstancing,
    bool isFlipSided,
    bool useTangent,
    out vec3 transformedNormal,
    out vec3 transformedTangent
) {
    transformedNormal = objectNormal;
    transformedTangent = objectTangent;

    // Handle Batching
    if (useBatching) {
        mat3 bm = mat3(batchingMatrix);
        transformedNormal /= vec3(dot(bm[0], bm[0]), dot(bm[1], bm[1]), dot(bm[2], bm[2]));
        transformedNormal = bm * transformedNormal;
        if (useTangent) transformedTangent = bm * transformedTangent;
    }

    // Handle Instancing
    if (useInstancing) {
        mat3 im = mat3(instanceMatrix);
        transformedNormal /= vec3(dot(im[0], im[0]), dot(im[1], im[1]), dot(im[2], im[2]));
        transformedNormal = im * transformedNormal;
        if (useTangent) transformedTangent = im * transformedTangent;
    }

    // Move to View Space
    transformedNormal = normalMatrix * transformedNormal;

    if (isFlipSided) {
        transformedNormal = -transformedNormal;
    }

    if (useTangent) {
        // modelViewMatrix is required for tangent transform
        mat4 modelViewMatrix = viewMatrix * modelMatrix;
        transformedTangent = (modelViewMatrix * vec4(transformedTangent, 0.0)).xyz;
        if (isFlipSided) transformedTangent = -transformedTangent;
    }

    // Set the varying for the fragment shader
    vNormal = normalize(transformedNormal);
}
