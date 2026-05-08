
/**
 * Flutter GPU requires uniforms to be in blocks for efficiency.
 * This should be part of your Material layout (Binding 1).
 */
layout(set = 0, binding = 1) uniform MaterialUniforms {
    vec4 uDiffuseColor; // Example of shared material block
    float uAlphaTest;   // Your converted 'alphaTest' uniform
};
