#version 460 core

// Include files mapping structural logic (Ensure paths match your project tree)
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/uv_pars_fragment.frag"
#include "../shader_chunk/map_pars_fragment.frag"
#include "../shader_chunk/alphamap_pars_fragment.frag"
#include "../shader_chunk/alphatest_pars_fragment.frag"
#include "../shader_chunk/alphahash_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// UNIFORMS BLOCK (Shared continuous layout tracker across your app pipeline)
uniform ObjectUniforms {
    mat4 modelMatrix;            // Vertex stage overhead (Indices 0 through 15)
};

uniform MaterialUniforms {
    float opacity;               // Float Index 16
    float depthPackingMode;      // Float Index 17 (Pass 3200.0 for Basic, 3201.0 for RGBA Packing)
};

// Variable name must match the 'out vec2 vHighPrecisionZW;' declaration in your vertex shader
in vec2 vHighPrecisionZW;

// Explicit fragment pipeline output 
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 diffuseColor = vec4(1.0);

    #include "../shader_chunk/clipping_planes_fragment.frag"

    // Replaced #if DEPTH_PACKING macro branches with strict numeric float checks
    if (depthPackingMode == 3200.0) {
        diffuseColor.a = opacity;
    }

    #include "../shader_chunk/map_fragment.frag"
    #include "../shader_chunk/alphamap_fragment.frag"
    #include "../shader_chunk/alphatest_fragment.frag"
    #include "../shader_chunk/alphahash_fragment.frag"
    #include "../shader_chunk/logdepthbuf_fragment.frag"

    // Higher precision equivalent of gl_FragCoord.z
    float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;

    // Handle structural rendering branches natively based on lookups
    if (depthPackingMode == 3200.0) {
        fragColor = vec4(vec3(1.0 - fragCoordZ), opacity);
    } else if (depthPackingMode == 3201.0) {
        // packDepthToRGBA is loaded out of packing.frag under the hood
        fragColor = packDepthToRGBA(fragCoordZ);
    } else {
        // Fallback default catch-all to prevent unassigned color states
        fragColor = vec4(vec3(fragCoordZ), 1.0);
    }
}
