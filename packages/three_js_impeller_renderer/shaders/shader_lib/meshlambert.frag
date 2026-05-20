#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/dithering_pars_fragment.frag"
#include "../shader_chunk/color_pars_fragment.frag"
#include "../shader_chunk/uv_pars_fragment.frag"
#include "../shader_chunk/map_pars_fragment.frag"
#include "../shader_chunk/alphamap_pars_fragment.frag"
#include "../shader_chunk/alphatest_pars_fragment.frag"
#include "../shader_chunk/alphahash_pars_fragment.frag"
#include "../shader_chunk/aomap_pars_fragment.frag"
#include "../shader_chunk/lightmap_pars_fragment.frag"
#include "../shader_chunk/emissivemap_pars_fragment.frag"
#include "../shader_chunk/envmap_common_pars_fragment.frag"
#include "../shader_chunk/envmap_pars_fragment.frag"
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/bsdfs.frag"
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/normal_pars_fragment.frag"
#include "../shader_chunk/lights_lambert_pars_fragment.frag"
#include "../shader_chunk/shadowmap_pars_fragment.frag"
#include "../shader_chunk/bumpmap_pars_fragment.frag"
#include "../shader_chunk/normalmap_pars_fragment.frag"
#include "../shader_chunk/specularmap_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Keeping this block aligned to follow your 32-slot base vertex matrix sequence.
uniform MaterialUniforms {
    vec3 diffuse;      // Float Indices 32, 33, 34 (Base color)
    vec3 emissive;     // Float Indices 35, 36, 37 (Glow color)
    float opacity;     // Float Index 38           (Alpha blending)
};

// 3. PIPELINE INPUTS (Interpolated variables from vertex stage)
in vec3 vNormal;
in vec2 vUv;

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    #include "../shader_chunk/clipping_planes_fragment.frag"

    // Instantiate lighting accumulation storage structs
    ReflectedLight reflectedLight = ReflectedLight(vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0));
    vec3 totalEmissiveRadiance = emissive;

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map_fragment.frag"
    #include "../shader_chunk/color_fragment.frag"
    #include "../shader_chunk/alphamap_fragment.frag"
    #include "../shader_chunk/alphatest_fragment.frag"
    #include "../shader_chunk/alphahash_fragment.frag"
    #include "../shader_chunk/specularmap_fragment.frag"
    
    // Evaluate geometry normals and normal modifications
    #include "../shader_chunk/normal_fragment_begin.frag"
    #include "../shader_chunk/normal_fragment_maps.frag"
    #include "../shader_chunk/emissivemap_fragment.frag"

    // Accumulate diffuse light computations
    #include "../shader_chunk/lights_lambert_fragment.frag"
    #include "../shader_chunk/lights_fragment_begin.frag"
    #include "../shader_chunk/lights_fragment_maps.frag"
    #include "../shader_chunk/lights_fragment_end.frag"

    // Ambient occlusion modulation
    #include "../shader_chunk/aomap_fragment.frag"

    // Combine diffuse lighting components with emission glow values
    vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;

    #include "../shader_chunk/envmap_fragment.frag"
    #include "../shader_chunk/opaque_fragment.frag"
    #include "../shader_chunk/tonemapping_fragment.frag"
    #include "../shader_chunk/colorspace_fragment.frag"
    #include "../shader_chunk/fog_fragment.frag"
    #include "../shader_chunk/premultiplied_alpha_fragment.frag"
    #include "../shader_chunk/dithering_fragment.frag"

    // Route the final color output directly to the frame buffer target
    fragColor = vec4(outgoingLight, diffuseColor.a);
}
