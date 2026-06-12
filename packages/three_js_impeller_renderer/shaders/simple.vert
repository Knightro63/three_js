#version 460 core

// 1. Uniform structure defined natively
layout(set = 0, binding = 0) uniform UniformBuffer {
    mat4 modelViewMatrix;
} ubo;

// 2. Vertex layout parameters
layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec4 inColor;

layout(location = 0) out vec4 outColor;

void main() {
    gl_Position = ubo.modelViewMatrix * vec4(inPosition, 1.0);
    outColor = inColor;
}
