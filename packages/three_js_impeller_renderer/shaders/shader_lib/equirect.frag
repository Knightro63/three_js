#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float backgroundIntensity; // For consistency with other background shaders
};

// Binding 61: tEquirect (New dedicated binding for Equirectangular maps)
layout(binding = 61) uniform sampler2D tEquirect;

// Location 10: vWorldPosition (Received from Vertex 6)
layout(location = 10) in vec3 vWorldPosition;

// Location 54: Final color redirected
layout(location = 54) out vec4 pc_fragColor;

// Helper: equirectUv (Inlined from <common>)
vec2 equirectUv(vec3 dir) {
    float PI = 3.141592653589793;
    float tPI = 6.283185307179586;
    vec2 uv = vec2(atan(dir.z, dir.x) / tPI + 0.5, acos(dir.y) / PI);
    return uv;
}

void main() {
    vec3 direction = normalize(vWorldPosition);
    vec2 sampleUV = equirectUv(direction);
    
    vec4 texColor = texture(tEquirect, sampleUV);

    // Apply background intensity if needed
    // texColor.rgb *= backgroundIntensity;

    // Tonemapping and Colorspace conversion applied here
    pc_fragColor = texColor;
}
