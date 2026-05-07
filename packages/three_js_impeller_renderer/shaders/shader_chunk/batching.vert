#version 460 core

/**
 * Converts the batchingVertex snippet.
 * This assumes getBatchingMatrix and batchId are defined 
 * in batching_pars.vert or the same file.
 */
mat4 applyBatching() {
    // Calls the utility function using the input batchId
    return getBatchingMatrix(batchId);
}
