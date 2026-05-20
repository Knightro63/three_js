#version 460 core

// 1. INPUT ATTRIBUTES (From your Flutter mesh geometry)
in vec3 position;
in vec2 uv;

// 2. UNIFORMS BLOCK
uniform VertexUniforms {
    // A mat3 takes exactly 9 floats in memory.
    // Flutter maps these to slots 0 through 8 sequentially.
    mat3 uvTransform; 
};

// 3. OUTPUTS (Must match the variable name in your fragment shader exactly)
out vec2 vUv;

void main() {
    // Calculate transformed texture coordinates
    vUv = (uvTransform * vec3(uv, 1.0)).xy;
    
    // Set standard projection coordinate output
    gl_Position = vec4(position.xy, 1.0, 1.0);
}