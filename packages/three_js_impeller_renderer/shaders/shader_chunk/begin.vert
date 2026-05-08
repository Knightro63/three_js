
// Input attribute from your mesh data
layout(location = 0) in vec3 inPosition;

// Output to Fragment Shader (matches your Master List Location 0)
layout(location = 0) out vec3 vPosition;

/**
 * Converts beginVertex snippet.
 * Initializes the 'transformed' variable used in subsequent 
 * displacement or skinning snippets.
 */
vec3 beginVertexTransform() {
    vec3 transformed = vec3(inPosition);
    
    // Assigning to the varying for Alpha Hashing
    vPosition = inPosition;
    
    return transformed;
}
