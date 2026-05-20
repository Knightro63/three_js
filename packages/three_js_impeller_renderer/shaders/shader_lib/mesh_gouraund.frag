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
#include "../shader_chunk/aomap_pars_fragment.frag"
#include "../shader_chunk/lightmap_pars_fragment.frag"
#include "../shader_chunk/emissivemap_pars_fragment.frag"
#include "../shader_chunk/envmap_common_pars_fragment.frag"
#include "../shader_chunk/envmap_pars_fragment.frag"
#include "../shader_chunk/bsdfs.frag"
#include "../shader_chunk/lights_pars_begin.frag"
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/shadowmap_pars_fragment.frag"
#include "../shader_chunk/shadowmask_pars_fragment.frag"
#include "../shader_chunk/specularmap_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Stacking this directly behind your 32-slot base vertex matrix block projection sequence.
uniform MaterialUniforms {
    vec3 diffuse;            // Float Indices 32, 33, 34
    vec3 emissive;           // Float Indices 35, 36, 37
    float opacity;           // Float Index 38
    float lightMapIntensity; // Float Index 39
    bool isDoubleSided;      // Float Index 40 (Converted from DOUBLE_SIDED macro)
    bool useLightMap;        // Float Index 41 (Converted from USE_LIGHTMAP macro)
};

// 3. TEXTURE SAMPLERS (Decoupled image list independent of uniform float indexes)
uniform sampler2D lightMap;  // Sampler Index 0

// 4. PIPELINE INPUTS (Varyings passed down from vertex Gouraud calculations)
in vec3 vLightFront;
in vec3 vIndirectFront;
in vec3 vLightBack;
in vec3 vIndirectBack;
in vec2 vLightMapUv;

// 5. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    #include "../shader_chunk/clipping_planes_fragment.frag"
    
    vec4 diffuseColor = vec4(diffuse, opacity);
    ReflectedLight reflectedLight = ReflectedLight(vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0));
    vec3 totalEmissiveRadiance = emissive;

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map_fragment.frag"
    #include "../shader_chunk/color_fragment.frag"
    #include "../shader_chunk/alphamap_fragment.frag"
    #include "../shader_chunk/alphatest_fragment.frag"
    #include "../shader_chunk/specularmap_fragment.frag"
    #include "../shader_chunk/emissivemap_fragment.frag"

    // ACCUMULATION: Indirect Diffuse Lighting Branch
    if (isDoubleSided) {
        // gl_FrontFacing is a native built-in fragment parameter supported by Impeller
        reflectedLight.indirectDiffuse += (gl_FrontFacing) ? vIndirectFront : vIndirectBack;
    } else {
        reflectedLight.indirectDiffuse += vIndirectFront;
    }

    if (useLightMap) {
        // Modern GLSL handles standard overloads implicitly via texture()
        vec4 lightMapTexel = texture(lightMap, vLightMapUv);
        vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
        reflectedLight.indirectDiffuse += lightMapIrradiance;
    }

    // BRDF_Lambert is evaluated out of your bsdfs.frag chunk dependencies
    reflectedLight.indirectDiffuse *= BRDF_Lambert(diffuseColor.rgb);

    // ACCUMULATION: Direct Diffuse Lighting Branch
    if (isDoubleSided) {
        reflectedLight.directDiffuse = (gl_FrontFacing) ? vLightFront : vLightBack;
    } else {
        reflectedLight.directDiffuse = vLightFront;
    }

    reflectedLight.directDiffuse *= BRDF_Lambert(diffuseColor.rgb) * getShadowMask();

    // MODULATION
    #include "../shader_chunk/aomap_fragment.frag"

    vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;

    #include "../shader_chunk/envmap_fragment.frag"
    #include "../shader_chunk/opaque_fragment.frag"
    #include "../shader_chunk/tonemapping_fragment.frag"
    #include "../shader_chunk/colorspace_fragment.frag"
    #include "../shader_chunk/fog_fragment.frag"
    #include "../shader_chunk/premultiplied_alpha_fragment.frag"
    #include "../shader_chunk/dithering_fragment.frag"

    // Route final pixel color vector to the destination buffer
    fragColor = vec4(outgoingLight, diffuseColor.a);
}
