#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    float flipEnvMap;
    float backgroundBlurriness;
    float backgroundIntensity;
    mat3 backgroundRotation;
    bool isCubeMap;   // Replacement for ENVMAP_TYPE_CUBE
    bool isCubeUV;    // Replacement for ENVMAP_TYPE_CUBE_UV
};

// Binding 10: envMap (Atlas-style for Flutter GPU compatibility)
layout(binding = 10) uniform sampler2D envMap;

// Location 10: vWorldPosition (Used for world direction logic)
layout(location = 10) in vec3 vWorldPosition; 

layout(location = 0) out vec4 fragColor;

// Note: <cube_uv_reflection_fragment>, <tonemapping_fragment>, 
// and <colorspace_fragment> logic must be included here as raw functions 
// or inline code to maintain SPIR-V compatibility without includes.

void main() {
    vec3 dir = backgroundRotation * vWorldPosition;
    vec4 texColor = vec4(0.0, 0.0, 0.0, 1.0);

    if (isCubeMap) {
        // Mapping Cube to 2D Atlas logic
        vec3 lookupDir = vec3(flipEnvMap * dir.x, dir.yz);
        // texColor = sampleCubeAs2D(envMap, lookupDir); // Placeholder for atlas helper
    } else if (isCubeUV) {
        // texColor = textureCubeUV(envMap, dir, backgroundBlurriness); 
    }

    texColor.rgb *= backgroundIntensity;

    // Apply manual Tone Mapping and Color Space conversion here
    
    fragColor = texColor;
}
