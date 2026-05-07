#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
    float uAlphaTest;
    bool useMap;
    bool useAlphaHash;
};

// Binding 60: map (Using the dedicated basic/simple diffuse slot)
layout(binding = 60) uniform sampler2D map;

// Stage Inputs
layout(location = 8) in vec4 vColor; // Synced with Vertex 15

// Final Output
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    // Particle Point Coord logic: gl_PointCoord is built-in for Points
    if (useMap) {
        diffuseColor *= texture(map, gl_PointCoord);
    }

    // Vertex Color modulation
    diffuseColor *= vColor;

    // Alpha Test
    if (diffuseColor.a < uAlphaTest) discard;

    vec3 outgoingLight = diffuseColor.rgb;

    // Final Output (Opaque/Premultiplied logic simplified)
    pc_fragColor = vec4(outgoingLight, diffuseColor.a);
}
