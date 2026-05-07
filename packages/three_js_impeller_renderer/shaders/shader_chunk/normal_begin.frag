#version 460 core

/**
 * Note: Requires getTangentFrame() utility if not using vertex tangents.
 */

// Inputs from Master List
layout(location = 3)  in vec3 vNormal;
layout(location = 13) in vec3 vViewPosition;
layout(location = 25) in vec3 vTangent;   // Sequential after vMetalnessMapUv (24)
layout(location = 26) in vec3 vBitangent;

/**
 * Converts normalFragmentBegin logic.
 * Establishes the 'normal', 'tbn', and 'nonPerturbedNormal' variables.
 */
void setupNormalFrame(
    bool isFlatShaded, 
    bool isDoubleSided, 
    bool useTangent,
    out vec3 normal,
    out vec3 nonPerturbedNormal,
    out mat3 tbn,
    out mat3 tbn2
) {
    // gl_FrontFacing is built-in to GLSL 4.60
    float faceDirection = gl_FrontFacing ? 1.0 : -1.0;

    if (isFlatShaded) {
        vec3 fdx = dFdx(vViewPosition);
        vec3 fdy = dFdy(vViewPosition);
        normal = normalize(cross(fdx, fdy));
    } else {
        normal = normalize(vNormal);
        if (isDoubleSided) normal *= faceDirection;
    }

    // Capture base normal before mapping
    nonPerturbedNormal = normal;

    // Build Primary TBN Frame
    if (useTangent) {
        tbn = mat3(normalize(vTangent), normalize(vBitangent), normal);
    } else {
        // Fallback to procedural tangent generation
        // getTangentFrame would need -vViewPosition, normal, and the active UV
        // tbn = getTangentFrame(...); 
    }

    // Build Clearcoat TBN Frame
    tbn2 = tbn; 

    if (isDoubleSided && !isFlatShaded) {
        tbn[0] *= faceDirection;
        tbn[1] *= faceDirection;
        tbn2[0] *= faceDirection;
        tbn2[1] *= faceDirection;
    }
}
