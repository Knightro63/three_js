#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"

// 2. INPUT MESH ATTRIBUTES
in vec3 position;

// 3. UNIFORMS BLOCK
// Keeping this block identical to your other files keeps your indexing uniform.
uniform ObjectUniforms {
    mat4 modelMatrix; // Float Indices 0 through 15 (Takes up 16 float slots)
};

// 4. PIPELINE OUTPUTS (Implicit varying matching)
// This matches your fragment shader 'in vec3 vWorldDirection;' variable name exactly.
out vec3 vWorldDirection;

void main() {
    // Calculate direction vectors by transforming local vertices via the model matrix
    vWorldDirection = transformDirection(position, modelMatrix);

    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"

    // Force the background depth to the maximum far clipping boundary (1.0 in NDC)
    gl_Position.z = gl_Position.w;
}
