#version 460 core

// 1. INPUT MESH ATTRIBUTES
in vec3 position;
in vec2 uv;

// 2. UNIFORMS BLOCK (Shared continuous layout tracker across your app pipeline)
uniform ObjectUniforms {
    mat4 projectionMatrix;   // Float Indices 0 through 15 (16 float slots)
    mat4 modelViewMatrix;    // Float Indices 16 through 31 (16 float slots)
};

// 3. PIPELINE OUTPUTS (Implicit varying matching)
// Matches your destination fragment shader 'in vec2 vUv;' variable name exactly.
out vec2 vUv;

void main() {
    vUv = uv;
    
    // Process standard projection coordinate output using the structured matrices
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}