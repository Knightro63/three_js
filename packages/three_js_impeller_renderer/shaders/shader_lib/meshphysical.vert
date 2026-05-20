#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"
#include "../shader_chunk/batching_pars_vertex.vert"
#include "../shader_chunk/uv_pars_vertex.vert"
#include "../shader_chunk/displacementmap_pars_vertex.vert"
#include "../shader_chunk/color_pars_vertex.vert"
#include "../shader_chunk/fog_pars_vertex.vert"
#include "../shader_chunk/normal_pars_vertex.vert"
#include "../shader_chunk/morphtarget_pars_vertex.vert"
#include "../shader_chunk/skinning_pars_vertex.vert"
#include "../shader_chunk/shadowmap_pars_vertex.vert"
#include "../shader_chunk/logdepthbuf_pars_vertex.vert"
#include "../shader_chunk/clipping_planes_pars_vertex.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;
in vec3 normal;
in vec2 uv;

// 3. UNIFORMS BLOCKS
// Maintained at slots 0 through 31 to cleanly align with your global pipeline pattern
uniform ObjectUniforms {
    mat4 projectionMatrix;   // Float Indices 0 through 15 (16 float slots)
    mat4 modelViewMatrix;    // Float Indices 16 through 31 (16 float slots)
};

uniform VertexConfigUniforms {
    bool useTransmission;    // Float Index 32 (Replaces compile-time USE_TRANSMISSION macro switch)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
// These link directly to your MeshStandard/MeshPhysical fragment shader inputs by variable string name
out vec3 vViewPosition;
out vec3 vWorldPosition;
out vec3 vNormal;            // Populated inside normal_vertex.vert chunk under the hood
out vec2 vUv;

void main() {
    #include "../shader_chunk/uv_vertex.vert"
    #include "../shader_chunk/color_vertex.vert"
    #include "../shader_chunk/morphinstance_vertex.vert"
    #include "../shader_chunk/morphcolor_vertex.vert"
    #include "../shader_chunk/batching_vertex.vert"
    
    // Evaluate geometry surface normals
    #include "../shader_chunk/beginnormal_vertex.vert"
    #include "../shader_chunk/morphnormal_vertex.vert"
    #include "../shader_chunk/skinbase_vertex.vert"
    #include "../shader_chunk/skinnormal_vertex.vert"
    #include "../shader_chunk/defaultnormal_vertex.vert"
    #include "../shader_chunk/normal_vertex.vert"
    
    // Process core vertex coordinates and view spacing projections
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/morphtarget_vertex.vert"
    #include "../shader_chunk/skinning_vertex.vert"
    #include "../shader_chunk/displacementmap_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"
    #include "../shader_chunk/logdepthbuf_vertex.vert"
    #include "../shader_chunk/clipping_planes_vertex.vert"

    // mvPosition (ModelView position) is explicitly computed inside project_vertex.vert
    vViewPosition = -mvPosition.xyz;

    #include "../shader_chunk/worldpos_vertex.vert"
    #include "../shader_chunk/shadowmap_vertex.vert"
    #include "../shader_chunk/fog_vertex.vert"

    // Converted runtime branch: populates world coordinates if light transmission features are active
    if (useTransmission) {
        // worldPosition is populated internally by the worldpos_vertex.vert chunk above
        vWorldPosition = worldPosition.xyz;
    } else {
        vWorldPosition = vec3(0.0);
    }
}
