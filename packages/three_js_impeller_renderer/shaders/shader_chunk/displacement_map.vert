
// Binding 11: From displacementmap_pars.vert
layout(set = 0, binding = 11) uniform sampler2D displacementMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float displacementScale;
    float displacementBias;
};

// Location 4: Input attribute for displacement UVs
layout(location = 4) in vec2 inDisplacementMapUv;

/**
 * Converts displacementmapVertex logic.
 * Displaces the 'transformed' vertex position along the normal.
 */
void applyDisplacement(inout vec3 transformed, vec3 objectNormal) {
    // texture2D -> texture in 4.60
    float h = texture(displacementMap, inDisplacementMapUv).x;
    transformed += normalize(objectNormal) * (h * displacementScale + displacementBias);
}
