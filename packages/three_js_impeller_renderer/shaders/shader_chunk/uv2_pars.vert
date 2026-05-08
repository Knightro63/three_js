
/**
 * Location 30: Raw secondary UV attribute (inUv2) from the mesh.
 */
layout(location = 30) in vec2 uv2;

/**
 * Location 52: Output to Fragment Shader (vUv2).
 * Sequential after vAnisotropyVectorMapUv (51).
 */
layout(location = 52) out vec2 vUv2;

/**
 * Part of MaterialUniforms (Binding 1).
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    mat3 uv2Transform;
};
