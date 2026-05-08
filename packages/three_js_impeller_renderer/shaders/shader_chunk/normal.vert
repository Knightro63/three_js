
// Input for bitangent calculation
layout(location = 2) in vec4 inTangent; // inTangent.w is the sign

// Outputs to Fragment Shader (Sequential from Master List)
layout(location = 24) out vec3 vNormal;
layout(location = 25) out vec3 vTangent;
layout(location = 26) out vec3 vBitangent;

/**
 * Converts normalVertex logic.
 * normal is computed with derivatives in fragment shader if FLAT_SHADED.
 */
void applyNormalVertex(vec3 transformedNormal, vec3 transformedTangent, bool useTangent) {
    vNormal = normalize(transformedNormal);

    if (useTangent) {
        vTangent = normalize(transformedTangent);
        // Calculate bitangent using the normal, tangent, and the sign (w)
        vBitangent = normalize(cross(vNormal, vTangent) * inTangent.w);
    }
}
