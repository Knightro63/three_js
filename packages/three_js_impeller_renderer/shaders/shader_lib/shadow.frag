#version 460 core

// Binding 1: Material parameters
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 color;
    float opacity;
};

// Bindings 29, 33, 37: Shadow Maps (Blocks of 4)
layout(binding = 29) uniform sampler2D directionalShadowMap[4];
layout(binding = 33) uniform sampler2D spotShadowMap[4];
layout(binding = 37) uniform sampler2D pointShadowMap[4];

// Bindings 41, 45, 49: Shadow Uniforms
layout(std140, binding = 41) uniform DirectionalShadowUniforms { mat4 directionalShadowMatrix[4]; };
layout(std140, binding = 45) uniform SpotShadowUniforms { mat4 spotShadowMatrix[4]; };
layout(std140, binding = 49) uniform PointShadowUniforms { mat4 pointShadowMatrix[4]; };

// Shadow Coords from Vertex (Locations 29, 33, 37)
layout(location = 29) in vec4 vDirectionalShadowCoord[4];
layout(location = 33) in vec4 vSpotLightCoord[4];
layout(location = 37) in vec4 vPointShadowCoord[4];

// Output 54: Final fragment color
layout(location = 54) out vec4 pc_fragColor;

// Simplified Shadow Mask Logic (Replacement for getShadowMask)
float getShadowMask() {
    float shadow = 1.0;
    // Implementation would iterate through shadow maps and compare depth
    // using vDirectionalShadowCoord, vSpotLightCoord, etc.
    return shadow; 
}

void main() {
    float shadowMask = getShadowMask();
    
    pc_fragColor = vec4(color, opacity * (1.0 - shadowMask));
}
