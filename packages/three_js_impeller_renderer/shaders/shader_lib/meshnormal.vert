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
    bool needsViewPosition; // SPIR-V replacement for FLAT_SHADED || USE_BUMPMAP || etc.
};

// Binding 11: displacementMap
layout(binding = 11) uniform sampler2D displacementMap;

// Stage Inputs
layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 29) in vec2 inUv;

// Stage Outputs (Synced with Master List)
layout(location = 3)  out vec3 vNormal;       // View-space normal (Frag 3)
layout(location = 13) out vec3 vViewPosition;  // View-space position (Frag 13)
layout(location = 23) out vec2 vMapUv;        // Primary UV (Frag 23)

void main() {
    vMapUv = inUv;
    vec3 transformed = vec3(inPosition);
    vec3 objectNormal = inNormal;

    // Displacement Mapping
    if (useDisplacementMap) {
        transformed += normalize(objectNormal) * (texture(displacementMap, inUv).x * displacementScale + displacementBias);
    }

    // Normal Transformation (View Space)
    vNormal = normalize(uNormalMatrix * objectNormal);

    // Project and View Position
    vec4 worldPosition = uModelMatrix * vec4(transformed, 1.0);
    vec4 mvPosition = uViewMatrix * worldPosition;
    
    if (needsViewPosition) {
        vViewPosition = -mvPosition.xyz;
    }

    gl_Position = uModelViewProjection * vec4(transformed, 1.0);
}
