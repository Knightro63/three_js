#version 460 core

// Binding 10: Environment Map Atlas
layout(set = 0, binding = 10) uniform sampler2D envMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    float envMapIntensity;
    mat3 envMapRotation;
};

layout(set = 0, binding = 0) uniform FrameUniforms {
    mat4 viewMatrix;
};

/**
 * Note: textureCubeUV() and inverseTransformDirection() must be 
 * available via common.frag or cube_uv_reflection.frag.
 */

vec3 getIBLIrradiance(const in vec3 normal) {
    vec3 worldNormal = inverseTransformDirection(normal, viewMatrix);
    // Roughness 1.0 for diffuse irradiance
    vec4 envMapColor = textureCubeUV(envMap, envMapRotation * worldNormal, 1.0);
    return PI * envMapColor.rgb * envMapIntensity;
}

vec3 getIBLRadiance(const in vec3 viewDir, const in vec3 normal, const in float roughness) {
    vec3 reflectVec = reflect(-viewDir, normal);
    
    // Gram-Schmidt-like re-centering for rough surfaces
    reflectVec = normalize(mix(reflectVec, normal, roughness * roughness));
    reflectVec = inverseTransformDirection(reflectVec, viewMatrix);
    
    vec4 envMapColor = textureCubeUV(envMap, envMapRotation * reflectVec, roughness);
    return envMapColor.rgb * envMapIntensity;
}

vec3 getIBLAnisotropyRadiance(const in vec3 viewDir, const in vec3 normal, const in float roughness, const in vec3 bitangent, const in float anisotropy) {
    // https://google.github.io/filament/Filament.md.html#lighting/imagebasedlights/anisotropy
    vec3 bentNormal = cross(bitangent, viewDir);
    bentNormal = normalize(cross(bentNormal, bitangent));
    
    float weight = pow2(pow2(1.0 - anisotropy * (1.0 - roughness)));
    bentNormal = normalize(mix(bentNormal, normal, weight));
    
    return getIBLRadiance(viewDir, bentNormal, roughness);
}
