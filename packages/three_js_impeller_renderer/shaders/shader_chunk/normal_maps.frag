
// Binding 27: Dedicated sampler for the Normal Map
layout(set = 0, binding = 27) uniform sampler2D normalMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    vec2 normalScale;
};

layout(set = 0, binding = 0) uniform FrameUniforms {
    mat3 normalMatrix;
};

// Location 27: UV coordinates for Normal Mapping (Sequential after vBitangent at 26)
layout(location = 27) in vec2 vNormalMapUv;

/**
 * Converts normalFragmentMaps logic.
 * Note: Requires perturbNormalArb and dHdxy_fwd from bumpmap_pars.frag
 */
void applyNormalMap(
    inout vec3 normal, 
    mat3 tbn, 
    vec3 vViewPosition, 
    float faceDirection, 
    bool isObjectSpace, 
    bool isTangentSpace, 
    bool useBumpMap,
    bool isFlipSided
) {
    if (isObjectSpace) {
        // Overrides both flatShading and attribute normals
        normal = texture(normalMap, vNormalMapUv).xyz * 2.0 - 1.0;
        
        if (isFlipSided) normal = -normal;
        normal = normal * faceDirection;
        
        // Transform to view space
        normal = normalize(normalMatrix * normal);

    } else if (isTangentSpace) {
        vec3 mapN = texture(normalMap, vNormalMapUv).xyz * 2.0 - 1.0;
        
        // Scale the xy perturbation
        mapN.xy *= normalScale;
        
        // Transform from tangent space to view space using the TBN matrix
        normal = normalize(tbn * mapN);

    } else if (useBumpMap) {
        // Fallback to Bump Map logic if no Normal Map is active
        normal = perturbNormalArb(-vViewPosition, normal, dHdxy_fwd(), faceDirection);
    }
}
