#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/cube_uv_reflection.frag"
#include "../shader_chunk/tonemapping_pars.frag"

// CRITICAL IMPELLER CHANGE: Remove 'std140' layout block parameters and binding indexes.
// Impeller packs uniform blocks down automatically and maps them to a single uniform struct in Dart.
uniform MaterialUniforms {
    mat3 backgroundRotation; // Place highest alignment structures at the top to prevent memory padding gaps
    float flipEnvMap;
    float backgroundBlurriness;
    float backgroundIntensity;
    bool isCubeMap;
    bool isCubeUV;
};

// CRITICAL IMPELLER CHANGE: Strip descriptor sets and explicit binding tokens.
uniform sampler2D envMap;

// CRITICAL IMPELLER CHANGE: Remove hardcoded input location indexing (location = 10).
// Impeller links varyings natively based on variable name matching between vertex and fragment stages.
in vec3 vWorldPosition;

// Use default layout out location 0 for standard fragment pipeline output
layout(location = 0) out vec4 fragColor;

void main() {
    vec3 vWorldDirection = normalize(vWorldPosition);
    vec3 dir = backgroundRotation * vWorldDirection;
    vec4 texColor = vec4(0.0, 0.0, 0.0, 1.0);

    if (isCubeMap) {
        vec3 lookupDir = vec3(flipEnvMap * dir.x, dir.yz);
        // Modern GLSL note: standard 'texture()' natively handles overloaded sampler dimensions based on type definition
        texColor = textureCube(envMap, lookupDir); 
    } else if (isCubeUV) {
        texColor = textureCubeUV(envMap, dir, backgroundBlurriness);
    }

    texColor.rgb *= backgroundIntensity;
    vec3 outgoingLight = texColor.rgb;

    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"

    fragColor = vec4(outgoingLight, texColor.a);
}
