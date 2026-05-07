#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    mat4 uModelMatrix; // Added for transformDirection logic
    float uTime;
    vec2 uResolution;
};

// Stage Inputs
layout(location = 0) in vec3 inPosition;

// Stage Outputs (Synced with Frag 10)
layout(location = 6) out vec3 vWorldPosition; // vWorldDirection equivalent

void main() {
    // transformDirection logic: normalize( ( modelMatrix * vec4( position, 0.0 ) ).xyz )
    // In background shaders, the world position acts as the lookup direction
    vWorldPosition = normalize((uModelMatrix * vec4(inPosition, 0.0)).xyz);

    // Standard projection
    vec4 mvPosition = uModelViewProjection * vec4(inPosition, 1.0);
    
    // Set z to camera far (z = w)
    gl_Position = mvPosition.xyww;
}
