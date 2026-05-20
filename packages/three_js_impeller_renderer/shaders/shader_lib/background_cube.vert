#version 460 core

// 1. INCLUDE DECLARATIONS
#include "../shader_chunk/common.vert"

// Standard Three.js mesh input attributes mapped to clean Impeller vertex buffers
in vec3 position;

// Uniform structural grouping to replace loose WebGL/Three.js global bindings
uniform ObjectUniforms {
    mat4 modelMatrix;
};

// CRITICAL IMPELLER CHANGE: Implicit varying matching (Replaces legacy layout numbers or manual locations)
// Match this exact name as an 'in vec3 vWorldDirection;' inside your fragment shader.
out vec3 vWorldDirection;

void main() {
    // 2. CALCULATE DIRECTION
    // transformDirection maps local mesh vectors into world coordinates via the modelMatrix
    vWorldDirection = transformDirection(position, modelMatrix);

    // 3. CORE GEOMETRY
    #include "../shader_chunk/begin_vertex.vert"
    #include "../shader_chunk/project_vertex.vert"

    // 4. DEPTH TRICK
    // Forces the calculated depth to maximum depth (1.0 in NDC space)
    gl_Position.z = gl_Position.w; 
}
