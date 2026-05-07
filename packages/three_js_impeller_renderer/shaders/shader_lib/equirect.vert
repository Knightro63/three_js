#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    mat4 uModelMatrix;
    float uTime;
    vec2 uResolution;
};

// Stage Inputs
layout(location = 0) in vec3 inPosition;

// Stage Outputs (Synced with Frag 10)
layout(location = 6) out vec3 vWorldPosition; 

void main() {
    // transformDirection logic: normalize( ( modelMatrix * vec4( position, 0.0 ) ).xyz )
    vWorldPosition = normalize((uModelMatrix * vec4(inPosition, 0.0)).xyz);

    // Standard projection
    gl_Position = uModelViewProjection * vec4(inPosition, 1.0);
}
