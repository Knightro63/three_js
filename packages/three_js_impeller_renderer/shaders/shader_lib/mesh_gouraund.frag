#version 460 core

/**
 * Stage: Fragment
 * Purpose: Master template for Gouraud (per-vertex) Lambertian materials.
 */

#define GOURAUD

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/packing.frag"
#include "../shader_chunk/dithering_pars.frag"
#include "../shader_chunk/color_pars.frag"
#include "../shader_chunk/uv_pars.frag"
#include "../shader_chunk/map_pars.frag"
#include "../shader_chunk/alphamap_pars.frag"
#include "../shader_chunk/alphatest_pars.frag"
#include "../shader_chunk/aomap_pars.frag"
#include "../shader_chunk/lightmap_pars.frag"
#include "../shader_chunk/emissivemap_pars.frag"
#include "../shader_chunk/envmap_common_pars.frag"
#include "../shader_chunk/envmap_pars.frag"
#include "../shader_chunk/bsdfs.frag"
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/fog_pars.frag"
#include "../shader_chunk/shadowmap_pars.frag"
#include "../shader_chunk/shadowmask_pars.frag"
#include "../shader_chunk/specularmap_pars.frag"
#include "../shader_chunk/logdepthbuf_pars.frag"
#include "../shader_chunk/clipping_planes_pars.frag"

layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    vec3 emissive;
    float opacity;
    float lightMapIntensity;
    bool isDoubleSided;
};

// Varying Inputs per Master List (Calculated in the Vertex Shader)
layout(location = 14) in vec3 vLightFront;
layout(location = 15) in vec3 vIndirectFront;
layout(location = 16) in vec3 vLightBack;
layout(location = 17) in vec3 vIndirectBack;

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
    #include "../shader_chunk/specularmap.frag"
    #include "../shader_chunk/emissivemap.frag"

    // 2. ACCUMULATION (Using Vertex-Interpolated Lighting)
    
    // Indirect Diffuse
    if (isDoubleSided) {
        reflectedLight.indirectDiffuse += ( gl_FrontFacing ) ? vIndirectFront : vIndirectBack;
    } else {
        reflectedLight.indirectDiffuse += vIndirectFront;
    }

    #include "../shader_chunk/lightmap_fragment.frag" // Logic for lightMapIntensity and vLightMapUv

    reflectedLight.indirectDiffuse *= BRDF_Lambert( diffuseColor.rgb );

    // Direct Diffuse
    if (isDoubleSided) {
        reflectedLight.directDiffuse = ( gl_FrontFacing ) ? vLightFront : vLightBack;
    } else {
        reflectedLight.directDiffuse = vLightFront;
    }

    // Apply Shadows to the pre-calculated direct light
    reflectedLight.directDiffuse *= BRDF_Lambert( diffuseColor.rgb ) * getShadowMask();

    // 3. MODULATION & FINAL ASSEMBLY
    #include "../shader_chunk/aomap.frag"

    vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;

    #include "../shader_chunk/envmap.frag"
    
    // Standard pipeline finalizing
    #include "../shader_chunk/tonemapping.frag"
    #include "../shader_chunk/colorspace.frag"
    #include "../shader_chunk/fog.frag"
    #include "../shader_chunk/premultiplied_alpha.frag"
    #include "../shader_chunk/dithering.frag"

    pc_fragColor = vec4( outgoingLight, diffuseColor.a );
}
