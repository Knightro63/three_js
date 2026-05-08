
/**
 * Note: Requires boneMatX..W from skinbase.vert and matrices from skinning_pars.vert.
 * Depends on the 'transformed' variable initialized in begin.vert.
 */

// Vertex Attributes for Skinning (Sequential after vBitangent at 26)
layout(location = 27) in ivec4 skinIndex;
layout(location = 28) in vec4  skinWeight;

/**
 * Converts skinningVertex logic.
 * Transforms the 'transformed' position into skinned space.
 */
void applySkinning(
    inout vec3 transformed,
    mat4 bindMatrix,
    mat4 bindMatrixInverse,
    mat4 boneMatX,
    mat4 boneMatY,
    mat4 boneMatZ,
    mat4 boneMatW
) {
    // 1. Transform to bind space
    vec4 skinVertex = bindMatrix * vec4(transformed, 1.0);
    vec4 skinned = vec4(0.0);

    // 2. Accumulate weighted bone transformations
    skinned += boneMatX * skinVertex * skinWeight.x;
    skinned += boneMatY * skinVertex * skinWeight.y;
    skinned += boneMatZ * skinVertex * skinWeight.z;
    skinned += boneMatW * skinVertex * skinWeight.w;

    // 3. Transform back to object space
    transformed = (bindMatrixInverse * skinned).xyz;
}
