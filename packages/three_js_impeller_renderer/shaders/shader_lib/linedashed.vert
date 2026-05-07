#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    float uTime;
    vec2 uResolution;
};

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float scale;
    float dashSize;
    float totalSize;
};

// Stage Inputs
layout(location = 0) in vec3 inPosition;
layout(location = 4) in vec4 color;        // Raw vertex color
layout(location = 32) in float lineDistance; // New attribute: Mesh line distance

// Stage Outputs
layout(location = 33) out float vLineDistance;
layout(location = 15) out vec4 vColor;

void main() {
    vLineDistance = scale * lineDistance;
    vColor = color;

    // Standard projection
    gl_Position = uModelViewProjection * vec4(inPosition, 1.0);
}
