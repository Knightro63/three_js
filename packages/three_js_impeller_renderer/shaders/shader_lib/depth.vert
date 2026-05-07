#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    float uTime;
    vec2 uResolution;
};

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    bool useDisplacementMap;
    float displacementScale;
    float displacementBias;
};

// Binding 11: displacementMap
layout(binding = 11) uniform sampler2D displacementMap;

// Stage Inputs
layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 29) in vec2 inUv;

// Stage Outputs
layout(location = 23) out vec2 vMapUv;      // Synced to Frag 23
layout(location = 22) out float vFragDepth; // Synced to Frag 22 (vHighPrecisionZW replacement)

void main() {
    vMapUv = inUv;

    vec3 transformed = vec3(inPosition);

    // SPIR-V branching for Displacement Map
    if (useDisplacementMap) {
        transformed += normalize(inNormal) * (texture(displacementMap, inUv).x * displacementScale + displacementBias);
    }

    // Standard Project Vertex
    gl_Position = uModelViewProjection * vec4(transformed, 1.0);

    // High precision depth equivalent: 0.5 * z / w + 0.5
    vFragDepth = 0.5 * gl_Position.z / gl_Position.w + 0.5;
}
