#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/uv_pars_fragment.frag"
#include "../shader_chunk/map_pars_fragment.frag"
#include "../shader_chunk/alphamap_pars_fragment.frag"
#include "../shader_chunk/alphatest_pars_fragment.frag"
#include "../shader_chunk/alphahash_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCK (Shared continuous layout tracker across your app pipeline)
uniform ObjectUniforms {
    mat4 modelMatrix;       // Vertex stage memory overhead (Indices 0 through 15)
};

uniform DistanceUniforms {
    vec3 referencePosition;  // Float Indices 16, 17, 18 (Point light coordinates)
    float nearDistance;      // Float Index 19
    float farDistance;       // Float Index 20
};

// 3. PIPELINE INPUTS (Implicit varying matching)
// Variable name must match the 'out vec3 vWorldPosition;' declaration in your vertex shader
in vec3 vWorldPosition;

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main () {
    vec4 diffuseColor = vec4(1.0);

    #include "../shader_chunk/clipping_planes_fragment.frag"
    #include "../shader_chunk/map_fragment.frag"
    #include "../shader_chunk/alphamap_fragment.frag"
    #include "../shader_chunk/alphatest_fragment.frag"
    #include "../shader_chunk/alphahash_fragment.frag"

    // Calculate distance from the current vertex point to the reference point light source
    float dist = length(vWorldPosition - referencePosition);
    
    // Normalize distance between your custom linear clipping boundary bounds
    dist = (dist - nearDistance) / (farDistance - nearDistance);
    
    // WebGL 'saturate' maps to standard GLSL 'clamp' functionality
    dist = clamp(dist, 0.0, 1.0); 

    // Encode the single floating point depth into 4-channel byte space
    // 'packDepthToRGBA' is provided directly via the 'packing.frag' include file
    fragColor = packDepthToRGBA(dist);
}
