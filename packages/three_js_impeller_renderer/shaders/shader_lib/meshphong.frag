#version 460 core

/**
 * Stage: Fragment
 * Purpose: Master template for specular-inclusive lighting (Phong).
 */

#define PHONG

// 1. DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/dithering_pars.frag"
#include "../shader_chunk/color_pars.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"
#include "../shader_chunk/alphamap_pars.frag"
#include "../shader_chunk/alphatest_pars.frag"
#include "../shader_chunk/alpha_hash_pars.frag"
#include "../shader_chunk/aomap_pars.frag"
#include "../shader_chunk/lightmap_pars.frag"
#include "../shader_chunk/emissivemap_pars.frag"
#include "../shader_chunk/envmap_common_pars.frag"
#include "../shader_chunk/envmap_pars.frag"
#include "../shader_chunk/fog_pars.frag"
#include "../shader_chunk/bsdfs.frag"
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/normal_pars.frag"
#include "../shader_chunk/lights_phong_pars.frag"
#include "../shader_chunk/shadowmap_pars.frag"
#include "../shader_chunk/bumpmap_pars.frag"
#include "../shader_chunk/normalmap_pars.frag"
#include "../shader_chunk/specularmap_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

// Uniforms from Binding 1
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    vec3 emissive;
    vec3 specular;
    float shininess;
    float opacity;
};

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec4 diffuseColor = vec4( diffuse, opacity );
    ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
    vec3 totalEmissiveRadiance = emissive;

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map.frag"
    #include "../shader_chunk/color.frag"
    #include "../shader_chunk/alphamap.frag"
    #include "../shader_chunk/alphatest.frag"
    #include "../shader_chunk/alpha_hash_fragment.frag"
    #include "../shader_chunk/specularmap.frag"
    
    // Setup Normal and TBN
    #include "../shader_chunk/normal_fragment_begin.frag"
    #include "../shader_chunk/normal_fragment_maps.frag"
    #include "../shader_chunk/emissivemap.frag"

    // 2. ACCUMULATION (Lighting Execution)
    #include "../shader_chunk/lights_phong_fragment.frag"
    #include "../shader_chunk/lights_fragment_begin.frag"
    #include "../shader_chunk/lights_fragment_maps.frag"
    #include "../shader_chunk/lights_fragment_end.frag"

    // 3. MODULATION & FINAL ASSEMBLY
    #include "../shader_chunk/aomap.frag"
    
    vec3 outgoingLight = reflectedLight.directDiffuse + 
                         reflectedLight.indirectDiffuse + 
                         reflectedLight.directSpecular + 
                         reflectedLight.indirectSpecular + 
                         totalEmissiveRadiance;

    #include "../shader_chunk/envmap.frag"
    
    // Standard modular output chain
    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"
    #include "../shader_chunk/premultiplied_alpha.frag"
    #include "../shader_chunk/dithering.frag"

    pc_fragColor = vec4( outgoingLight, diffuseColor.a );
}
