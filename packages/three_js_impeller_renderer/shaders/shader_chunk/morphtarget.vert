#version 460 core

/**
 * Note: Requires getMorph() and morphTargetInfluences/BaseInfluence.
 * Depends on morphtarget_pars.vert.
 */

// Fallback Vertex Attributes (if not using MORPHTARGETS_TEXTURE)
layout(location = 16) in vec3 morphTarget0;
layout(location = 17) in vec3 morphTarget1;
layout(location = 18) in vec3 morphTarget2;
layout(location = 19) in vec3 morphTarget3;
layout(location = 20) in vec3 morphTarget4;
layout(location = 21) in vec3 morphTarget5;
layout(location = 22) in vec3 morphTarget6;
layout(location = 23) in vec3 morphTarget7;

/**
 * Converts morphtargetVertex logic.
 * Displaces the 'transformed' position by blending with target positions.
 */
void applyMorphTarget(inout vec3 transformed, bool useMorphTexture) {
    // Apply base influence logic
    transformed *= morphTargetBaseInfluence;

    if (useMorphTexture) {
        for (int i = 0; i < 8; i++) {
            if (morphTargetInfluences[i] != 0.0) {
                // Index 0 is reserved for Position data in the morph texture array
                transformed += getMorph(gl_VertexID, i, 0).xyz * morphTargetInfluences[i];
            }
        }
    } else {
        // Attribute-based fallback
        transformed += morphTarget0 * morphTargetInfluences[0];
        transformed += morphTarget1 * morphTargetInfluences[1];
        transformed += morphTarget2 * morphTargetInfluences[2];
        transformed += morphTarget3 * morphTargetInfluences[3];
        transformed += morphTarget4 * morphTargetInfluences[4];
        transformed += morphTarget5 * morphTargetInfluences[5];
        transformed += morphTarget6 * morphTargetInfluences[6];
        transformed += morphTarget7 * morphTargetInfluences[7];
    }
}
