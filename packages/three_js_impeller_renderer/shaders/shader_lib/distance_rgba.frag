#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 referencePosition;
    float nearDistance;
    float farDistance;
    float uAlphaTest;
    bool useMap;
    bool useAlphaMap;
};

// Binding 60: map
layout(binding = 60) uniform sampler2D map;

// Binding 2: alphaMap
layout(binding = 2) uniform sampler2D alphaMap;

// Location 10: vWorldPosition (Synced with Vertex 6)
layout(location = 10) in vec3 vWorldPosition;
// Location 23: vMapUv
layout(location = 23) in vec2 vMapUv;
// Location 1: vAlphaMapUv
layout(location = 1) in vec2 vAlphaMapUv;

// Location 54: pc_fragColor
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

    float dist = length(vWorldPosition - referencePosition);
    dist = (dist - nearDistance) / (farDistance - nearDistance);
    dist = clamp(dist, 0.0, 1.0); // saturate equivalent

    pc_fragColor = packDepthToRGBA(dist);
}
