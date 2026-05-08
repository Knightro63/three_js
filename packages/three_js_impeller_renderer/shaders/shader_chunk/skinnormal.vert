
/**
 * Note: Requires boneMatX..W, skinWeight, bindMatrix, and bindMatrixInverse.
 * Modifies objectNormal and objectTangent in-place.
 */
void applySkinningNormal(
    inout vec3 objectNormal, 
    inout vec3 objectTangent, 
    mat4 bindMatrix, 
    mat4 bindMatrixInverse, 
    mat4 boneMatX, 
    mat4 boneMatY, 
    mat4 boneMatZ, 
    mat4 boneMatW,
    vec4 skinWeight,
    bool useTangent
) {
    // Construct the combined skin matrix based on weights
    mat4 skinMatrix = mat4(0.0);
    skinMatrix += skinWeight.x * boneMatX;
    skinMatrix += skinWeight.y * boneMatY;
    skinMatrix += skinWeight.z * boneMatZ;
    skinWeight += skinWeight.w * boneMatW;

    // Transform matrix into bind space
    skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;

    // Apply to normal (w = 0.0 to ignore translation)
    objectNormal = (skinMatrix * vec4(objectNormal, 0.0)).xyz;

    if (useTangent) {
        objectTangent = (skinMatrix * vec4(objectTangent, 0.0)).xyz;
    }
}
