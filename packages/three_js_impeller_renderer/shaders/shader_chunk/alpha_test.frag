#version 460 core

layout(set = 0, binding = 1) uniform MaterialUniforms {
    vec4 uDiffuseColor;
    float uAlphaTest;
};

/**
 * Converts the alphatestFragment snippet.
 * Note: ALPHA_TO_COVERAGE is typically a pipeline state toggle in Flutter GPU, 
 * but the logic is provided here as a function if you wish to emulate it.
 */

// Version 1: Standard Alpha Test (Hard Cutoff)
void applyAlphaTest(inout vec4 diffuseColor) {
    if (diffuseColor.a < uAlphaTest) {
        discard;
    }
}

// Version 2: Alpha to Coverage (Smooth Cutoff)
void applyAlphaToCoverage(inout vec4 diffuseColor) {
    // smoothstep(edge0, edge1, x)
    diffuseColor.a = smoothstep(uAlphaTest, uAlphaTest + fwidth(diffuseColor.a), diffuseColor.a);
    if (diffuseColor.a == 0.0) {
        discard;
    }
}
