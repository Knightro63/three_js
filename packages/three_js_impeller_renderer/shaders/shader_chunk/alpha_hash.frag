
// Input from vertex shader (World or Local position)
layout(location = 0) in vec3 vPosition;

/**
 * Converts the snippet: 
 * if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;
 * 
 * Note: getAlphaHashThreshold() must be defined in the same file 
 * or included via your shader compiler logic.
 */
void applyAlphaHash(vec4 diffuseColor) {
    if (diffuseColor.a < getAlphaHashThreshold(vPosition)) {
        discard;
    }
}
