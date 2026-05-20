#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars_vertex.vert"
#include "../shader_chunk/uv_pars_vertex.vert"
#include "../shader_chunk/envmap_pars_vertex.vert"
#include "../shader_chunk/color_pars_vertex.vert"
#include "../shader_chunk/fog_pars_vertex.vert"
#include "../shader_chunk/morphtarget_pars_vertex.vert"
#include "../shader_chunk/skinning_pars_vertex.vert"
#include "../shader_chunk/logdepthbuf_pars_vertex.vert"
#include "../shader_chunk/clipping_planes_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;
in vec3 normal;
in vec2 uv;

// 3. UNIFORMS BLOCKS
uniform ObjectUniforms {
    mat4 projectionMatrix;   // Float Indices 0 through 15 (16 float slots)
    mat4 modelViewMatrix;    // Float Indices 16 through 31 (16 float slots)
};

uniform VertexConfigUniforms {
    bool useEnvMap;          // Float Index 32 (Pass 1.0 for true, 0.0 for false)
    bool useSkinning;         // Float Index 33 (Pass 1.0 for true, 0.0 for false)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
// These link to your MeshBasic fragment shader variables exactly by string name
out vec3 vNormal;
out vec2 vLightMapUv;

void main() {
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphinstance_vertex.vert"
    #include "../shader_chunk/morphcolor_vertex.vert"
    #include "../shader_chunk/batching_vertex.vert"

    // Replaced legacy preprocessor macro check with a native runtime branch evaluation
    if (useEnvMap || useSkinning) {
        #include "../shader_chunk/beginnormal_vertex.vert"
        #include "../shader_chunk/morphnormal_vertex.vert"
        #include "../shader_chunk/skinbase_vertex.vert"
        #include "../shader_chunk/skinnormal_vertex.vert"
        #include "../shader_chunk/defaultnormal_vertex.vert"
    }

    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget_vertex.vert"
    #include "../shader_chunk/skinning_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes_vertex.vert"
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/envmap_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
