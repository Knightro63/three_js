#version 460 core

/**
 * Binding 4: Texture containing matrix data for batching/instancing.
 */
layout(set = 0, binding = 4) uniform sampler2D batchingTexture;

/**
 * Location 3: The ID for the current instance/batch.
 * Replaces 'attribute float batchId'.
 */
layout(location = 3) in float batchId;

mat4 getBatchingMatrix(const in float i) {
    // textureSize and texelFetch are native in GLSL 4.60
    int size = textureSize(batchingTexture, 0).x;
    int j = int(i) * 4;
    int x = j % size;
    int y = j / size;

    // Fetch the 4 columns of the mat4
    vec4 v1 = texelFetch(batchingTexture, ivec2(x,     y), 0);
    vec4 v2 = texelFetch(batchingTexture, ivec2(x + 1, y), 0);
    vec4 v3 = texelFetch(batchingTexture, ivec2(x + 2, y), 0);
    vec4 v4 = texelFetch(batchingTexture, ivec2(x + 3, y), 0);

    return mat4(v1, v2, v3, v4);
}
