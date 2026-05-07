#version 460 core

// Binding 0: Frame Uniforms
layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 projectionMatrix;
    // ... other frame uniforms
};

// Outputs to Fragment Shader (Vertex Stage)
layout(location = 9) out float vIsPerspective;
layout(location = 10) out float vFragDepth;

/**
 * Converts logdepthbufVertex logic.
 * Note: gl_Position must be calculated before calling this.
 */
void applyLogDepthVertex() {
    // 1.0 + gl_Position.w provides the distance for log depth scaling
    vFragDepth = 1.0 + gl_Position.w;
    
    // Convert boolean check to 0.0 or 1.0 for the fragment shader
    vIsPerspective = isPerspectiveMatrix(projectionMatrix) ? 1.0 : 0.0;
}
