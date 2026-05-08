#version 460 core

/**
 * Stage: Fragment
 * Purpose: Master template for MatCap materials.
 */

#define MATCAP

// 1. DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.frag"
#include "../shader_chunk/dithering_pars.frag"
#include "../shader_chunk/color_pars.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"
#include "../shader_chunk/alphamap_pars.frag"
#include "../shader_chunk/alphatest_pars.frag"
#include "../shader_chunk/alpha_hash_pars.frag"
#include "../shader_chunk/fog_pars.frag"
#include "../shader_chunk/normal_pars.frag"
#include "../shader_chunk/bumpmap_pars.frag"
#include "../shader_chunk/normalmap_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
    bool useMatcap; // Toggle for USE_MATCAP
    // ... rest of UBO
};

// Binding 10: MatCap sampler (using envMap slot per Master List context)
layout(set = 0, binding = 10) uniform sampler2D matcap;

// Location 13: vViewPosition synced with Vertex 13
layout(location = 13) in vec3 vViewPosition;

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec4 diffuseColor = vec4( diffuse, opacity );

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map.frag"
    #include "../shader_chunk/color.frag"
    #include "../shader_chunk/alphamap.frag"
    #include "../shader_chunk/alphatest.frag"
    #include "../shader_chunk/alpha_hash_fragment.frag"
    
    // Normal handling (establishes 'normal' variable)
    #include "../shader_chunk/normal_fragment_begin.frag"
    #include "../shader_chunk/normal_fragment_maps.frag"

    // 2. MATCAP CALCULATION
    vec3 viewDir = normalize( vViewPosition );
    vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
    vec3 y = cross( viewDir, x );
    
    // Generate UVs based on surface normal relative to camera view
    vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;

    vec4 matcapColor;
    if (useMatcap) {
        matcapColor = texture( matcap, uv );
    } else {
        // Procedural default if matcap is missing
        matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );
    }

    vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;

    // 3. FINALIZE & OUTPUT
    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"
    #include "../shader_chunk/premultiplied_alpha.frag"
    #include "../shader_chunk/dithering.frag"

    pc_fragColor = vec4( outgoingLight, diffuseColor.a );
}
