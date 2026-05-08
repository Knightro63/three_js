#version 460 core

/**
 * Stage: Fragment
 * Purpose: Equirectangular environment projection.
 */

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/tonemapping_pars.frag"

// Binding 61: Dedicated texture map for equirectangular projections per Master List
layout(set = 0, binding = 61) uniform sampler2D tEquirect;

// Location 10: vWorldPosition/Direction per Master List (Synced with Vertex 10)
layout(location = 10) in vec3 vWorldPosition;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    // direction logic
    vec3 direction = normalize( vWorldPosition );
    
    // equirectUv is provided by common.frag
    vec2 sampleUV = equirectUv( direction );
    
    vec4 texColor = texture( tEquirect, sampleUV );

    // Apply lighting chain to outgoingLight
    vec3 outgoingLight = texColor.rgb;

    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"

    pc_fragColor = vec4( outgoingLight, texColor.a );
}
