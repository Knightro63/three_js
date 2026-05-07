#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    mat4 uModelMatrix;
    mat4 uViewMatrix;
    mat3 uNormalMatrix;
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
layout(location = 4) in vec4 color;
layout(location = 29) in vec2 inUv;

// Stage Outputs (Synced with Frag Master List)
layout(location = 23) out vec2 vMapUv;         // Frag 23
layout(location = 8)  out vec4 vColor;         // Frag 8
layout(location = 3)  out vec3 vNormal;        // Frag 3 (View-space normal)
layout(location = 13) out vec3 vViewPosition;   // Frag 13

void main() {
    vMapUv = inUv;
    vColor = color;

    vec3 transformed = vec3(inPosition);
    vec3 objectNormal = inNormal;

    // Displacement Map Logic
    if (useDisplacementMap) {
        transformed += normalize(objectNormal) * (texture(displacementMap, inUv).x * displacementScale + displacementBias);
    }

    // Normal Transform (View Space)
    vNormal = normalize(uNormalMatrix * objectNormal);

    // Position calculation
    vec4 worldPosition = uModelMatrix * vec4(transformed, 1.0);
    vec4 mvPosition = uViewMatrix * worldPosition;
    vViewPosition = -mvPosition.xyz;

    // Standard Projection
    gl_Position = uModelViewProjection * vec4(transformed, 1.0);
}
