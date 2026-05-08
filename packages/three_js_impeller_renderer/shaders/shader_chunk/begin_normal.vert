
// Input attributes from mesh
layout(location = 1) in vec3 inNormal;   // Standard vertex normal
layout(location = 2) in vec4 inTangent;  // Standard vertex tangent (xyz) + bitangent sign (w)

/**
 * Converts beginnormalVertex snippet.
 * Initializes 'objectNormal' and 'objectTangent' for use in 
 * subsequent lighting or normal mapping snippets.
 */
void beginNormalTransform(out vec3 objectNormal, out vec3 objectTangent) {
    objectNormal = vec3(inNormal);
    
    // Logic for USE_TANGENT
    objectTangent = vec3(inTangent.xyz);
}
