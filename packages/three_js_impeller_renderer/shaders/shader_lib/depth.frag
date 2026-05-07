#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float opacity;
    float uAlphaTest;
    int depthPacking; // 3200: Basic, 3201: RGBA
    bool useMap;
    bool useAlphaMap;
    bool useAlphaHash;
};

// Bindings for Alpha/Map
layout(binding = 2)  uniform sampler2D alphaMap;
layout(binding = 60) uniform sampler2D map;

// Inputs from Vertex
layout(location = 23) in vec2 vMapUv;      // Synced to Vertex 29/Frag 23
layout(location = 1)  in vec2 vAlphaMapUv; // Synced to Vertex 29/Frag 1
layout(location = 22) in float vFragDepth; // High-precision depth (w + 1.0) logic

// Output 54: Final color redirected
layout(location = 54) out vec4 pc_fragColor;

// Helper: packDepthToRGBA
vec4 packDepthToRGBA(float v) {
    vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
    enc = fract(enc);
    enc -= enc.yzww * vec4(1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0);
    return enc;
}

void main() {
    vec4 diffuseColor = vec4(1.0);
    
    if (useMap) {
        diffuseColor *= texture(map, vMapUv);
    }
    
    if (useAlphaMap) {
        diffuseColor.a *= texture(alphaMap, vAlphaMapUv).g;
    }

    if (diffuseColor.a < uAlphaTest) discard;

    // Depth calculation based on interpolated vFragDepth (vHighPrecisionZW equivalent)
    float fragCoordZ = vFragDepth; 

    if (depthPacking == 3200) {
        pc_fragColor = vec4(vec3(1.0 - fragCoordZ), opacity);
    } else if (depthPacking == 3201) {
        pc_fragColor = packDepthToRGBA(fragCoordZ);
    }
}
