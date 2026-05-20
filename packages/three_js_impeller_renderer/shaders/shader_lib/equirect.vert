#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;

// 3. UNIFORMS BLOCK
// Keeping this block identical across files maintains unified layout indexes
uniform ObjectUniforms {
    mat4 modelMatrix; // Float Indices 0 through 15 (Takes up 16 float slots)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
// Matches your fragment shader 'in vec3 vWorldDirection;' variable name exactly.
out vec3 vWorldDirection;

void main() {
    // Transform mesh vertex directions into world coordinate space
    vWorldDirection = transformDirection(position, modelMatrix);

    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"
}
