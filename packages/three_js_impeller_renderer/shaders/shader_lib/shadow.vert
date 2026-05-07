#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    mat4 uModelMatrix;
    float uTime;
    vec2 uResolution;
};

// Binding 41: DirectionalShadowUniforms (Block of 4 matrices)
layout(std140, binding = 41) uniform DirectionalShadowUniforms {
    mat4 directionalShadowMatrix[4];
};

// Stage Inputs
layout(location = 0) in vec3 inPosition;

// Stage Outputs (Shadow Coord Blocks per Master List)
layout(location = 29) out vec4 vDirectionalShadowCoord[4]; // Synced with Frag 29
layout(location = 33) out vec4 vSpotLightCoord[4];        // Synced with Frag 33
layout(location = 37) out vec4 vPointShadowCoord[4];       // Synced with Frag 37

void main() {
    vec4 worldPosition = uModelMatrix * vec4(inPosition, 1.0);
    
    // Shadow coordinate calculation (Simplified placeholder for block iteration)
    for (int i = 0; i < 4; i++) {
        vDirectionalShadowCoord[i] = directionalShadowMatrix[i] * worldPosition;
        vSpotLightCoord[i] = vec4(0.0);  // Logic for spot/point would be inlined here
        vPointShadowCoord[i] = vec4(0.0);
    }

    // Standard projection
    gl_Position = uModelViewProjection * vec4(inPosition, 1.0);
}
