
// Binding 0: Standard Frame Uniforms
layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 projectionMatrix;
    mat4 modelViewMatrix;
};

// Location 0: Input attribute from mesh
layout(location = 0) in vec3 inPosition;

/**
 * Converts: gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
 */
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(inPosition, 1.0);
}
