
/**
 * Stage: Vertex
 * Binding 53: Dedicated port for bone matrices.
 */

// Function to be defined in skinning_pars.vert
mat4 getBoneMatrix(int index);

/**
 * Retrieves the bone matrices for the current vertex's influences.
 */
void getSkinningMatrices(
    ivec4 skinIndex, 
    out mat4 boneMatX, 
    out mat4 boneMatY, 
    out mat4 boneMatZ, 
    out mat4 boneMatW
) {
    boneMatX = getBoneMatrix(skinIndex.x);
    boneMatY = getBoneMatrix(skinIndex.y);
    boneMatZ = getBoneMatrix(skinIndex.z);
    boneMatW = getBoneMatrix(skinIndex.w);
}
