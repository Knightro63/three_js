#version 460 core

// 1. INPUT MESH ATTRIBUTES
// Flutter streams the quad vertex buffer into this register
in vec3 position;

void main() {
    // Directly output the 2D clip-space coordinates
    gl_Position = vec4(position, 1.0);
}
