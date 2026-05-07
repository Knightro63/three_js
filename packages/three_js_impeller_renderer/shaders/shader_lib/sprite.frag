#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
    float uAlphaTest;
    bool useMap;
    bool useAlphaMap;
};

// Binding 60: map (Using the dedicated basic/simple diffuse slot)
layout(binding = 60) uniform sampler2D map;

// Binding 2: alphaMap
layout(binding = 2) uniform sampler2D alphaMap;

// Location 53: vUv (Synced with Vertex 31)
layout(location = 53) in vec2 vUv;

// Final Output
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    if (useMap) {
        diffuseColor *= texture(map, vUv);
    }

    if (useAlphaMap) {
        diffuseColor.a *= texture(alphaMap, vUv).g;
    }

    // Alpha Test
    if (diffuseColor.a < uAlphaTest) discard;

    vec3 outgoingLight = diffuseColor.rgb;

    // Final Output
    pc_fragColor = vec4(outgoingLight, diffuseColor.a);
}
