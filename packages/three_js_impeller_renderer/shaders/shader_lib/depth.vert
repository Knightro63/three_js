#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars_vertex.vert"
#include "../shader_chunk/uv_pars_vertex.vert"
#include "../shader_chunk/displacementmap_pars_vertex.vert"
#include "../shader_chunk/morphtarget_pars_vertex.vert"
#include "../shader_chunk/skinning_pars_vertex.vert"
#include "../shader_chunk/logdepthbuf_pars_vertex.vert"
#include "../shader_chunk/clipping_planes_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;
in vec2 uv;

// 3. UNIFORMS BLOCK
uniform ObjectUniforms {
    mat4 modelMatrix;           // Float Indices 0 through 15
};

uniform VertexConfigUniforms {
    float useDisplacementMap;   // Float Index 16 (Pass 1.0 for true, 0.0 for false)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
// Matches your depth-packing fragment shader 'in vec2 vHighPrecisionZW;' exactly.
out vec2 vHighPrecisionZW;

void main() {
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/batching_vertex.vert"
    #include "../shader_chunk/skinbase_vertex.vert"
    #include "../shader_chunk/morphinstance_vertex.vert"

    // Replaced macro #ifdef with a strict runtime control flag check
    if (useDisplacementMap == 1.0) {
        #include "../shader_chunk/beginnormal_vertex.vert"
        #include "../shader_chunk/morphnormal_vertex.vert"
        #include "../shader_chunk/skinnormal_vertex.vert"
    }

    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget_vertex.vert"
    #include "../shader_chunk/skinning_vertex.vert"
    #include "../shader_chunk/displacementmap_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes_vertex.vert"

    // Forward vector variables to the fragment hardware pipeline stage
    vHighPrecisionZW = gl_Position.zw;
}
