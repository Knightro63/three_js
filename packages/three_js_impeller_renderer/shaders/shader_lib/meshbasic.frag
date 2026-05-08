#version 460 core

/**
 * Stage: Fragment
 * Purpose: Master template for unlit materials (Basic).
 */

// 1. INCLUDE DECLARATIONS (The "Pars" snippets)
#include "../shader_chunk/common.frag"
#include "../shader_chunk/dithering_pars.frag"
#include "../shader_chunk/color_pars.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"
#include "../shader_chunk/alphamap_pars.frag"
#include "../shader_chunk/alphatest_pars.frag"
#include "../shader_chunk/alpha_hash_pars.frag"
#include "../shader_chunk/aomap_pars.frag"
#include "../shader_chunk/lightmap_pars.frag"
#include "../shader_chunk/envmap_common_pars.frag"
#include "../shader_chunk/envmap_pars.frag"
#include "../shader_chunk/fog_pars.frag"
#include "../shader_chunk/specularmap_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

// Uniforms from Binding 1
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
    float lightMapIntensity;
    // ... (rest of UBO)
};

// Final Output per Master List
layout(location = 0) out vec4 pc_fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"

    vec4 diffuseColor = vec4( diffuse, opacity );
    ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map.frag"
    #include "../shader_chunk/color.frag"
    #include "../shader_chunk/alphamap.frag"
    #include "../shader_chunk/alphatest.frag"
    #include "../shader_chunk/alpha_hash_fragment.frag"
    #include "../shader_chunk/specularmap.frag"

    // 2. ACCUMULATION (Baked Indirect Only)
    // lightMap is at Binding 16 per Master List
    if (uUseLightMap) {
        vec4 lightMapTexel = texture( lightMap, vLightMapUv );
        reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;
    } else {
        reflectedLight.indirectDiffuse += vec3( 1.0 );
    }

    // 3. MODULATION
    #include "../shader_chunk/aomap.frag"
    reflectedLight.indirectDiffuse *= diffuseColor.rgb;

    vec3 outgoingLight = reflectedLight.indirectDiffuse;

    #include "../shader_chunk/envmap.frag"

    // 4. FINALIZE & OUTPUT
    // Standard unlit assembly
    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"
    #include "../shader_chunk/premultiplied_alpha.frag"
    #include "../shader_chunk/dithering.frag"

    pc_fragColor = vec4( outgoingLight, diffuseColor.a );
}
