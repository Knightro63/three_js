#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars_vertex.vert"
#include "../shader_chunk/fog_pars_vertex.vert"
#include "../shader_chunk/morphtarget_pars_vertex.vert"
#include "../shader_chunk/skinning_pars_vertex.vert"
#include "../shader_chunk/shadowmap_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;
in vec3 normal;

// 3. UNIFORMS BLOCK
// Maintained at slots 0 through 31 to align with your global engine layout pattern
uniform ObjectUniforms {
    mat4 projectionMatrix;   // Float Indices 0 through 15 (16 float slots)
    mat4 modelViewMatrix;    // Float Indices 16 through 31 (16 float slots)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching for downstream shadows/fog)
out vec3 vNormal;
out vec2 vUv;

void main() {
    #include "../shader_chunk/batching_vertex.vert"
    
    // Evaluate geometry surface and bone normals for proper lighting alignment
    #include "../shader_chunk/beginnormal_vertex.vert"
    #include "../shader_chunk/morphinstance_vertex.vert"
    #include "../shader_chunk/morphnormal_vertex.vert"
    #include "../shader_chunk/skinbase_vertex.vert"
    #include "../shader_chunk/skinnormal_vertex.vert"
    #include "../shader_chunk/defaultnormal_vertex.vert"
    
    // Process core vertex coordinates and viewport space projections
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget_vertex.vert"
    #include "../shader_chunk/skinning_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    
    // Evaluate transform vectors for shadows and atmospheric fog computations
    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/shadowmap_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"
}
