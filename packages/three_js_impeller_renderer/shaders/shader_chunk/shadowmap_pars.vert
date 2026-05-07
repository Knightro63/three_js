#version 460 core

/**
 * Binding 41, 45, 49: Blocks of mat4 for shadow projection.
 * Locations 29, 33, 37: Outputting to the fragment shader lanes.
 */

layout(set = 0, binding = 41) uniform DirectionalShadowUniforms {
    mat4 directionalShadowMatrix[4];
};

layout(set = 0, binding = 45) uniform SpotShadowUniforms {
    mat4 spotShadowMatrix[4];
    mat4 spotLightMatrix[4]; // Combined if necessary
};

layout(set = 0, binding = 49) uniform PointShadowUniforms {
    mat4 pointShadowMatrix[4];
};

// Vertex Outputs - Synced with Fragment Inputs
layout(location = 29) out vec4 vDirectionalShadowCoord[4];
layout(location = 33) out vec4 vSpotLightCoord[4];
layout(location = 37) out vec4 vPointShadowCoord[4];

// Shadow parameter structs (for Bias calculations)
struct DirectionalLightShadow {
    float shadowBias;
    float shadowNormalBias;
    float shadowRadius;
    vec2 shadowMapSize;
};

struct SpotLightShadow {
    float shadowBias;
    float shadowNormalBias;
    float shadowRadius;
    vec2 shadowMapSize;
};

struct PointLightShadow {
    float shadowBias;
    float shadowNormalBias;
    float shadowRadius;
    vec2 shadowMapSize;
    float shadowCameraNear;
    float shadowCameraFar;
};
