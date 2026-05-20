#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/uv_pars_vertex.vert"
#include "../shader_chunk/color_pars_vertex.vert"
#include "../shader_chunk/fog_pars_vertex.vert"
#include "../shader_chunk/morphtarget_pars_vertex.vert"
#include "../shader_chunk/logdepthbuf_pars_vertex.vert"
#include "../shader_chunk/clipping_planes_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES (From your Flutter geometric vertex buffer data stream)
in vec3 position;
in vec2 uv;
in float lineDistance; // Replaced legacy WebGL 'attribute float'

// 3. UNIFORMS BLOCKS
uniform ObjectUniforms {
    mat4 projectionMatrix;   // Float Indices 0 through 15 (16 float slots)
    mat4 modelViewMatrix;    // Float Indices 16 through 31 (16 float slots)
};

uniform LineConfigUniforms {
    float scale;             // Float Index 32 (Sits directly behind your 32 matrix slots)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
// Matches your companion dashed-line fragment shader 'in float vLineDistance;' exactly.
out float vLineDistance;

void main() {
    // Apply structural line scale scaling factor transformations
    vLineDistance = scale * lineDistance;

    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphinstance_vertex.vert"
    #include "../shader_chunk/morphcolor_vertex.vert"
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
