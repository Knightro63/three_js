
/**
 * Note: Requires getMorph() and morphTargetInfluences/BaseInfluence.
 * Maps to Binding 1 (MaterialUniforms) or Binding 25 (Instance Texture).
 */

// Fallback Vertex Attributes (if not using MORPHTARGETS_TEXTURE)
layout(location = 11) in vec3 morphNormal0;
layout(location = 12) in vec3 morphNormal1;
layout(location = 13) in vec3 morphNormal2;
layout(location = 14) in vec3 morphNormal3;

/**
 * Converts morphnormalVertex logic.
 * Modifies objectNormal by blending with target normals.
 */
void applyMorphNormal(inout vec3 objectNormal, bool useMorphTexture) {
    // Apply base influence logic
    objectNormal *= morphTargetBaseInfluence;

    if (useMorphTexture) {
        for (int i = 0; i < 8; i++) {
            if (morphTargetInfluences[i] != 0.0) {
                // Index 1 is traditionally reserved for Normal data in the morph texture
                objectNormal += getMorph(gl_VertexID, i, 1).xyz * morphTargetInfluences[i];
            }
        }
    } else {
        // Attribute-based fallback (limited to 4 targets)
        objectNormal += morphNormal0 * morphTargetInfluences[0];
        objectNormal += morphNormal1 * morphTargetInfluences[1];
        objectNormal += morphNormal2 * morphTargetInfluences[2];
        objectNormal += morphNormal3 * morphTargetInfluences[3];
    }
}
