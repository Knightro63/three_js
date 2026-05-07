#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    mat3 uvTransform;
    float backgroundIntensity;
    bool decodeVideoTexture;
};

// Stage Inputs
layout(location = 0) in vec3 inPosition;
layout(location = 29) in vec2 inUv;

// Stage Outputs (Updated to 31 for Background isolation)
layout(location = 31) out vec2 vUv;

void main() {
    vUv = (uvTransform * vec3(inUv, 1.0)).xy;
    
    // Position logic for full-screen quad/background
    gl_Position = vec4(inPosition.xy, 1.0, 1.0);
}
