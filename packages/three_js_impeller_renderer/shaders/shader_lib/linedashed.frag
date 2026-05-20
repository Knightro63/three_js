#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.frag"
#include "../shader_chunk/color_pars_fragment.frag"
#include "../shader_chunk/uv_pars_fragment.frag"
#include "../shader_chunk/map_pars_fragment.frag"
#include "../shader_chunk/fog_pars_fragment.frag"
#include "../shader_chunk/logdepthbuf_pars_fragment.frag"
#include "../shader_chunk/clipping_planes_pars_fragment.frag"

// 2. UNIFORMS BLOCK
// Keeping this stacked sequentially mapping directly behind your vertex stage allocation bounds.
// Assuming your vertex shader uses the standard 32-slot layout (projection + view), these start at 32.
uniform MaterialUniforms {
    vec3 diffuse;      // Float Indices 32, 33, 34
    float opacity;     // Float Index 35
    float dashSize;    // Float Index 36
    float totalSize;   // Float Index 37
};

// 3. PIPELINE INPUTS (Implicit varying matching)
// Match this exact name as an 'out float vLineDistance;' inside your companion line vertex shader.
in float vLineDistance;

// 4. PIPELINE OUTPUTS
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    #include "../shader_chunk/clipping_planes_fragment.frag"

    // Line dashing condition: drops fragments matching gap intervals
    if (mod(vLineDistance, totalSize) > dashSize) {
        discard;
    }

    vec3 outgoingLight = vec3(0.0);

    #include "../shader_chunk/logdepthbuf_fragment.frag"
    #include "../shader_chunk/map_fragment.frag"
    #include "../shader_chunk/color_fragment.frag"

    outgoingLight = diffuseColor.rgb; // simple shader

    // Note: Traditional WebGL 'gl_FragColor' writes inside chunks need to be refactored 
    // to write directly to 'fragColor' or inline expanded safely here.
    #include "../shader_chunk/opaque_fragment.frag"
    #include "../shader_chunk/tonemapping_fragment.frag"
    #include "../shader_chunk/colorspace_fragment.frag"
    #include "../shader_chunk/fog_fragment.frag"
    #include "../shader_chunk/premultiplied_alpha_fragment.frag"

    // Ensure our custom output register maps the final computed alpha values
    fragColor = vec4(outgoingLight, diffuseColor.a);
}
