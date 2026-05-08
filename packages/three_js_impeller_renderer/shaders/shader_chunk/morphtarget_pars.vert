
/**
 * Binding 26: Texture Array containing morph data (Position, Normal, Color).
 * Layer index corresponds to the morph target index.
 */
layout(set = 0, binding = 26) uniform sampler2DArray morphTargetsTexture;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float morphTargetBaseInfluence;
    float morphTargetInfluences[8]; // Standardized to 8 targets
    ivec2 morphTargetsTextureSize;
    int   morphTargetsTextureStride; // Usually 3 (Pos, Norm, Color)
};

/**
 * Fetches morph data using texelFetch for high precision.
 * offset: 0 = Position, 1 = Normal, 2 = Color
 */
vec4 getMorph(const in int vertexIndex, const in int morphTargetIndex, const in int offset) {
    int texelIndex = vertexIndex * morphTargetsTextureStride + offset;
    int y = texelIndex / morphTargetsTextureSize.x;
    int x = texelIndex % morphTargetsTextureSize.x;
    
    // ivec3(x, y, layer) for sampler2DArray
    ivec3 morphUV = ivec3(x, y, morphTargetIndex);
    return texelFetch(morphTargetsTexture, morphUV, 0);
}
