vec3 evaluateNormal(vec3 worldNormal, vec3 worldPosition) {
    vec3 N = normalize(worldNormal);
    float isFlatShadingActive = material.pbrParams.z;
    
    if (isFlatShadingActive > 0.5) {
        // Reconstruct the true flat face normal using GLSL screen-space partial derivatives
        N = -normalize(cross(dFdx(worldPosition), dFdy(worldPosition)));
    }
    
    return N;
}
