#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    mat4 uViewMatrix;
    mat4 uModelMatrix;
    float uTime;
    vec2 uResolution;
};

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    mat3 uvTransform;
    float size;
    float scale;
    bool usePointsUv;
    bool useSizeAttenuation;
    bool isPerspective; // Passed to replace isPerspectiveMatrix()
};

// Stage Inputs
layout(location = 0) in vec3 inPosition;
layout(location = 4) in vec4 color;
layout(location = 29) in vec2 inUv;

// Stage Outputs
layout(location = 15) out vec4 vColor; // Synced with Frag 8
layout(location = 31) out vec2 vUv;    // Synced with Frag 53 (Background/Point UV slot)

void main() {
    // 1. Color and UV
    vColor = color;
    if (usePointsUv) {
        vUv = (uvTransform * vec3(inUv, 1.0)).xy;
    }

    // 2. Projection
    vec4 mvPosition = uViewMatrix * uModelMatrix * vec4(inPosition, 1.0);
    gl_Position = uModelViewProjection * vec4(inPosition, 1.0);

    // 3. Point Size & Attenuation
    gl_PointSize = size;
    if (useSizeAttenuation) {
        if (isPerspective) {
            gl_PointSize *= (scale / -mvPosition.z);
        }
    }
}
