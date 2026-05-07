#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float opacity;
    bool isFlatShaded;
    bool useBumpMap;
    bool useNormalMap;
    bool isOpaque; // Replacement for #ifdef OPAQUE
};

// Bindings for Normal modification
layout(binding = 5)  uniform sampler2D bumpMap;   // Binding 5
layout(binding = 27) uniform sampler2D normalMap; // Binding 27

// Inputs from Vertex
layout(location = 3)  in vec3 vNormal;         // View-space normal
layout(location = 13) in vec3 vViewPosition;   // View-space position
layout(location = 23) in vec2 vMapUv;          // Standard UV
layout(location = 27) in vec2 vNormalMapUv;    // Normal Map UV

// Output 54: Final color redirected
layout(location = 54) out vec4 pc_fragColor;

// Helper: packNormalToRGB
vec3 packNormalToRGB(vec3 normal) {
    return normalize(normal) * 0.5 + 0.5;
}

void main() {
    vec4 diffuseColor = vec4(0.0, 0.0, 0.0, opacity);

    // Normal calculation logic
    vec3 normal = normalize(vNormal);

    // If FLAT_SHADED, BUMPMAP, or NORMALMAP logic was inlined from <normal_fragment_maps>
    // it would use vViewPosition, vMapUv, etc. here.

    pc_fragColor = vec4(packNormalToRGB(normal), diffuseColor.a);

    if (isOpaque) {
        pc_fragColor.a = 1.0;
    }
}
