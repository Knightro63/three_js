
/**
 * Binding 9: Dedicated block for clipping planes.
 * Fixed size (8) is required for GLSL 4.60 stability in Flutter GPU.
 */
layout(set = 0, binding = 9) uniform ClippingUniforms {
    vec4 clippingPlanes[8]; 
    int numClippingPlanes;
    int unionClippingPlanes;
};

/**
 * Location 7: Position used for clipping math.
 * Interpolated from the vertex shader.
 */
layout(location = 7) in vec3 vClipPosition;
