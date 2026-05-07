#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
    float dashSize;
    float totalSize;
    bool useMap;
};

// Binding 60: map
layout(binding = 60) uniform sampler2D map;

// Location 55: vLineDistance (Synced with Vertex 8 - Reusing FogDepth slot for line math)
layout(location = 55) in float vLineDistance;
// Location 23: vMapUv
layout(location = 23) in vec2 vMapUv;
// Location 8: vColor (Interpolated vertex color)
layout(location = 8) in vec4 vColor;

// Location 54: Final color output
layout(location = 54) out vec4 pc_fragColor;

void main() {
    // Dash discard logic
    if (mod(vLineDistance, totalSize) > dashSize) {
        discard;
    }

    vec4 diffuseColor = vec4(diffuse, opacity);

    if (useMap) {
        diffuseColor *= texture(map, vMapUv);
    }

    // Mix vertex colors if applicable
    diffuseColor *= vColor;

    // Standard simple lighting/opaque logic
    pc_fragColor = diffuseColor;
}
