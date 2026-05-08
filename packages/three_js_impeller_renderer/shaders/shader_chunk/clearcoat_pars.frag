
// Binding 6: (Already assigned) clearcoatNormalMap
layout(set = 0, binding = 6) uniform sampler2D clearcoatNormalMap;

// Binding 7: Map for clearcoat intensity (thickness)
layout(set = 0, binding = 7) uniform sampler2D clearcoatMap;

// Binding 8: Map for clearcoat-specific roughness
layout(set = 0, binding = 8) uniform sampler2D clearcoatRoughnessMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms (uDiffuseColor, bumpScale, etc.)
    vec2 clearcoatNormalScale;
};
