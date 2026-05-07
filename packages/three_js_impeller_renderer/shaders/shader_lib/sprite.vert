#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    mat4 uViewMatrix;
    mat4 uModelMatrix;
    mat4 uProjectionMatrix;
    float uTime;
    vec2 uResolution;
};

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float rotation;
    vec2 center;
    bool useSizeAttenuation; // SPIR-V replacement for #ifndef logic
    bool isPerspective;      // Pre-calculated bool
};

// Stage Inputs
layout(location = 0) in vec3 inPosition;
layout(location = 29) in vec2 inUv;

// Stage Outputs
layout(location = 31) out vec2 vUv; // Synced with Frag 53

void main() {
    vUv = inUv;

    // Get world scale from model matrix columns
    vec2 scale;
    scale.x = length(vec3(uModelMatrix[0].x, uModelMatrix[0].y, uModelMatrix[0].z));
    scale.y = length(vec3(uModelMatrix[1].x, uModelMatrix[1].y, uModelMatrix[1].z));

    vec4 mvPosition = uViewMatrix * uModelMatrix * vec4( 0.0, 0.0, 0.0, 1.0 );

    // Handle size attenuation branching
    if (!useSizeAttenuation && isPerspective) {
        scale *= -mvPosition.z;
    }

    vec2 alignedPosition = (inPosition.xy - (center - vec2(0.5))) * scale;

    // Apply rotation
    vec2 rotatedPosition;
    rotatedPosition.x = cos(rotation) * alignedPosition.x - sin(rotation) * alignedPosition.y;
    rotatedPosition.y = sin(rotation) * alignedPosition.x + cos(rotation) * alignedPosition.y;

    mvPosition.xy += rotatedPosition;

    gl_Position = uProjectionMatrix * mvPosition;
}
