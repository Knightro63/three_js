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
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/normal_pars_fragment.frag"
#include "../shader_chunk/bumpmap_pars_fragment.frag"
#include "../shader_chunk/normalmap_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCKS
// Keeping this block aligned to follow your 32-slot base vertex matrix sequence.
uniform MaterialUniforms {
    vec3 diffuse;       // Float Indices 32, 33, 34
    float opacity;      // Float Index 35
    bool useMatcapTex;  // Float Index 36 (Converted from compile-time macro switch)
};

// 3. TEXTURE SAMPLERS
uniform sampler2D matcap; // Sampler Index 0 (De-coupled from the float array)

// 4. PIPELINE INPUTS (Interpolated variables from vertex stage)
in vec3 vViewPosition;
in vec3 vNormal; // Extracted dynamically inside normal_fragment_begin.frag

// 5. PIPELINE OUTPUTS
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
    
    // Evaluate geometry normals and normal map adjustments
    #include "../shader_chunk/normal_fragment_begin.frag"
    #include "../shader_chunk/normal_fragment_maps.frag"

    // Process Matcap camera coordinate alignment mapping vectors
    vec3 viewDir = normalize(vViewPosition);
    vec3 x = normalize(vec3(viewDir.z, 0.0, -viewDir.x));
    vec3 y = cross(viewDir, x);
    
    // Transform coordinates into spherical UV space
    // 0.495 scale coefficient eliminates rim boundary wrapping artifacts
    vec2 matcapUV = vec2(dot(x, normal), dot(y, normal)) * 0.495 + 0.5;

    vec4 matcapColor;
    if (useMatcapTex) {
        // Modern GLSL handles standard overloads implicitly via texture()
        matcapColor = texture(matcap, matcapUV);
    } else {
        // Fallback procedural shading layout if texture data is omitted
        matcapColor = vec4(vec3(mix(0.2, 0.8, matcapUV.y)), 1.0);
    }

    vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;

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
