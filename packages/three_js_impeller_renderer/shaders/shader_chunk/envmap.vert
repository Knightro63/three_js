
// Output to Fragment Shader (Vertex Locations per your update)
layout(location = 6) out vec3 vWorldPosition;
layout(location = 7) out vec3 vReflect;

layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 viewMatrix;
    vec3 cameraPosition;
    bool isOrthographic;
};

layout(set = 0, binding = 1) uniform MaterialUniforms {
    float refractionRatio;
};

/**
 * Converts envmapVertex logic.
 * Populates vWorldPosition or vReflect for the fragment shader.
 */
void applyEnvMapVertex(
    vec3 worldPosition, 
    vec3 transformedNormal, 
    bool useWorldPos, 
    bool isReflection
) {
    if (useWorldPos) {
        vWorldPosition = worldPosition;
    } else {
        vec3 cameraToVertex;
        if (isOrthographic) {
            // Extracts view direction from the view matrix
            cameraToVertex = normalize(vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));
        } else {
            cameraToVertex = normalize(worldPosition - cameraPosition);
        }

        // inverseTransformDirection should be in your common.vert or common.frag logic
        vec3 worldNormal = inverseTransformDirection(transformedNormal, viewMatrix);

        if (isReflection) {
            vReflect = reflect(cameraToVertex, worldNormal);
        } else {
            vReflect = refract(cameraToVertex, worldNormal, refractionRatio);
        }
    }
}
