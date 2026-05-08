#version 460 core

/**
 * Stage: Fragment
 * Purpose: Pack distance from light source into RGBA (Point Light Shadows).
 */

#define DISTANCE

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"
#include "../shader_chunk/alphamap_pars.frag"
#include "../shader_chunk/alphatest_pars.frag"
#include "../shader_chunk/alpha_hash_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 referencePosition; // Light position
    float nearDistance;
    float farDistance;
    // ... other material uniforms
};

// Location 10: Interpolated world position per Master List
layout(location = 10) in vec3 vWorldPosition;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec4 diffuseColor = vec4( 1.0 );

    #include "../shader_chunk/map.frag"
    #include "../shader_chunk/alphamap.frag"
    #include "../shader_chunk/alphatest.frag"
    #include "../shader_chunk/alpha_hash_fragment.frag"

    // Calculate linear distance from the light reference point
    float dist = length( vWorldPosition - referencePosition );
    
    // Normalize to [0.0, 1.0] range
    dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
    dist = saturate( dist ); 

    // Pack 32-bit float into 8-bit RGBA channels for the shadow map
    pc_fragColor = packDepthToRGBA( dist );
}
