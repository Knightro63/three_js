#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/cube_uv_reflection.frag"
#include "../shader_chunk/tonemapping_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    float flipEnvMap;
    float backgroundBlurriness;
    float backgroundIntensity;
    mat3 backgroundRotation;
    bool isCubeMap; 
    bool isCubeUV;  
};

// Binding 10: envMap (Atlas-style) per Master List
layout(set = 0, binding = 10) uniform sampler2D envMap;

// Location 10: vWorldPosition per Master List
layout(location = 10) in vec3 vWorldPosition;

// Note: Using Location 0 for background, or change to 54 if unifying
layout(location = 0) out vec4 fragColor;

void main() {
    vec3 vWorldDirection = normalize(vWorldPosition);
    vec3 dir = backgroundRotation * vWorldDirection;
    
    vec4 texColor = vec4(0.0, 0.0, 0.0, 1.0);

    if (isCubeMap) {
        vec3 lookupDir = vec3(flipEnvMap * dir.x, dir.yz);
        texColor = textureCube(envMap, lookupDir); 
    } 
    else if (isCubeUV) {
        texColor = textureCubeUV(envMap, dir, backgroundBlurriness);
    }

    texColor.rgb *= backgroundIntensity;

    vec3 outgoingLight = texColor.rgb;

    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"

    fragColor = vec4(outgoingLight, texColor.a);
}
