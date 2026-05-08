
/**
 * Note: Requires getMorph() utility and MORPHTARGETS_COUNT constant.
 * These are typically defined in a global morph_utils.vert file.
 */

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float morphTargetBaseInfluence;
    float morphTargetInfluences[8]; // Example fixed size for Flutter GPU
};

/**
 * Converts morphcolorVertex logic.
 * Modifies the vertex color based on morph target data.
 */
void applyMorphColor(inout vec4 vColor, bool useAlpha) {
    // Apply base influence
    vColor *= morphTargetBaseInfluence;

    for (int i = 0; i < 8; i++) {
        if (morphTargetInfluences[i] != 0.0) {
            // Index 2 is traditionally reserved for Color data in the morph texture
            vec4 morphColor = getMorph(gl_VertexID, i, 2);
            
            if (useAlpha) {
                vColor += morphColor * morphTargetInfluences[i];
            } else {
                vColor.rgb += morphColor.rgb * morphTargetInfluences[i];
            }
        }
    }
}
