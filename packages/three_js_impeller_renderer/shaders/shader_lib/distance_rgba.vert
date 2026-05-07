#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    mat4 uModelMatrix;
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

// Stage Outputs (Synced with Frag 10 and 23)
layout(location = 6)  out vec3 vWorldPosition; 
layout(location = 23) out vec2 vMapUv;

void main() {
    vMapUv = inUv;
    vec3 transformed = vec3(inPosition);

    if (useDisplacementMap) {
        transformed += normalize(inNormal) * (texture(displacementMap, inUv).x * displacementScale + displacementBias);
    }

    // World Position Calculation
    vec4 worldPosition = uModelMatrix * vec4(transformed, 1.0);
    vWorldPosition = worldPosition.xyz;

    // Standard Projection
    gl_Position = uModelViewProjection * vec4(transformed, 1.0);
}
