
/**
 * Binding 50: Texture for bone matrices.
 * Each matrix is stored as 4 consecutive RGBA pixels (16 floats).
 */
layout(set = 0, binding = 53) uniform sampler2D boneTexture;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    mat4 bindMatrix;
    mat4 bindMatrixInverse;
};

/**
 * Converts getBoneMatrix logic.
 * Fetches four texels to build a full mat4.
 */
mat4 getBoneMatrix(const in int i) {
    int size = textureSize(boneTexture, 0).x;
    int j = i * 4;
    int x = j % size;
    int y = j / size;

    // Fetch the 4 columns of the bone matrix
    vec4 v1 = texelFetch(boneTexture, ivec2(x, y), 0);
    vec4 v2 = texelFetch(boneTexture, ivec2(x + 1, y), 0);
    vec4 v3 = texelFetch(boneTexture, ivec2(x + 2, y), 0);
    vec4 v4 = texelFetch(boneTexture, ivec2(x + 3, y), 0);

    return mat4(v1, v2, v3, v4);
}
