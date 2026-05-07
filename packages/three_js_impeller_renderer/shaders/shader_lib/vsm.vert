#version 460 core

// Stage Inputs
layout(location = 0) in vec3 inPosition;

void main() {
    // Standard full-screen quad or clip-space pass-through
    gl_Position = vec4(inPosition, 1.0);
}
