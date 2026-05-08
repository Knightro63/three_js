#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"
#include "../shader_chunk/alphamap_pars.frag"
#include "../shader_chunk/alphatest_pars.frag"
#include "../shader_chunk/alpha_hash_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    float opacity;
    bool isPackingRGBA; // true for shadow maps (3201), false for raw depth (3200)
};

// High precision ZW from vertex shader
layout(location = 56) in vec2 vHighPrecisionZW;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec4 diffuseColor = vec4( 1.0 );
    diffuseColor.a = opacity;

    #include "../shader_chunk/map.frag"
    #include "../shader_chunk/alphamap.frag"
    #include "../shader_chunk/alphatest.frag"
    #include "../shader_chunk/alpha_hash_fragment.frag"
    #include "../shader_chunk/logdepthbuf_fragment.frag"

    // Higher precision equivalent of gl_FragCoord.z
    float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;

    if (isPackingRGBA) {
        // Shadow map depth packing (DEPTH_PACKING 3201)
        pc_fragColor = packDepthToRGBA( fragCoordZ );
    } else {
        // Raw visualized depth (DEPTH_PACKING 3200)
        pc_fragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
    }
}
