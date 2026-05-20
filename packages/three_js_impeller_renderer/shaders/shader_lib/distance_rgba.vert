#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars_vertex.vert"
#include "../shader_chunk/uv_pars_vertex.vert"
#include "../shader_chunk/displacementmap_pars_vertex.vert"
#include "../shader_chunk/morphtarget_pars_vertex.vert"
#include "../shader_chunk/skinning_pars_vertex.vert"
#include "../shader_chunk/clipping_planes_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;
in vec2 uv;

// 3. UNIFORMS BLOCK (Shared continuous layout tracker across your app pipeline)
uniform ObjectUniforms {
    mat4 modelMatrix;           // Float Indices 0 through 15
};

uniform VertexConfigUniforms {
    float useDisplacementMap;   // Float Index 16 (Pass 1.0 for true, 0.0 for false)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
// Matches your companion distance fragment shader 'in vec3 vWorldPosition;' exactly.
out vec3 vWorldPosition;

void main() {
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/batching_vertex.vert"
    #include "../shader_chunk/skinbase_vertex.vert"
    #include "../shader_chunk/morphinstance_vertex.vert"

    // Replaced legacy preprocessor macro check with a clean runtime control flag
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
    
    // Note: 'worldPosition' is declared inside the worldpos_vertex.vert chunk
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/clipping_planes_vertex.vert"

    // Forward the 3D world coordinate variable to the fragment pipeline stage
    vWorldPosition = worldPosition.xyz;
}
