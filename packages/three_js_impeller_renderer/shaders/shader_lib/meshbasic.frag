#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/dithering_pars_fragment.frag"
#include "../shader_chunk/color_pars_fragment.frag"
#include "../shader_chunk/uv_pars_fragment.frag"
#include "../shader_chunk/map_pars_fragment.frag"
#include "../shader_chunk/alphamap_pars_fragment.frag"
#include "../shader_chunk/alphatest_pars_fragment.frag"
#include "../shader_chunk/alphahash_pars_fragment.frag"
#include "../shader_chunk/aomap_pars_fragment.frag"
#include "../shader_chunk/lightmap_pars_fragment.frag"
#include "../shader_chunk/envmap_common_pars_fragment.frag"
#include "../shader_chunk/envmap_pars_fragment.frag"
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/specularmap_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Keeping this block aligned to follow your 32-slot base vertex projection matrix sequence.
uniform MaterialUniforms {
    vec3 diffuse;            // Float Indices 32, 33, 34
    float opacity;           // Float Index 35
    float lightMapIntensity; // Float Index 36
    bool isFlatShaded;       // Float Index 37 (Converted from macro switch)
    bool useLightMap;        // Float Index 38 (Converted from macro switch)
};

// 3. PIPELINE INPUTS (Implicit varying matching)
in vec3 vNormal;
// Note: Ensure vLightMapUv is declared in your vertex shader if useLightMap is true
in vec2 vLightMapUv; 

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    #include "../shader_chunk/clipping_planes_fragment.frag"
    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map_fragment.frag"
    #include "../shader_chunk/color_fragment.frag"
    #include "../shader_chunk/alphamap_fragment.frag"
    #include "../shader_chunk/alphatest_fragment.frag"
    #include "../shader_chunk/alphahash_fragment.frag"
    #include "../shader_chunk/specularmap_fragment.frag"

    // Local variable struct matching Three.js compilation requirements
    ReflectedLight reflectedLight = ReflectedLight(vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0));

    // Converted runtime branch: lightmap texture sampling logic
    if (useLightMap) {
        // Modern GLSL handles texture overloads implicitly via texture()
        vec4 lightMapTexel = texture(lightMap, vLightMapUv);
        reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;
    } else {
        reflectedLight.indirectDiffuse += vec3(1.0);
    }

    #include "../shader_chunk/aomap_fragment.frag"

    reflectedLight.indirectDiffuse *= diffuseColor.rgb;
    vec3 outgoingLight = reflectedLight.indirectDiffuse;

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
