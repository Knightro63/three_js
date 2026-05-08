
// Textures and Uniforms
layout(set = 0, binding = 3) uniform sampler2D aoMap;

layout(set = 0, binding = 1) uniform MaterialUniforms {
    float aoMapIntensity;
    float roughness; // Part of the PBR material state
};

// Inputs from vertex shader
layout(location = 2) in vec2 vAoMapUv;

/**
 * Converts: float ambientOcclusion = ( texture( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;
 * Note: Uses texture() instead of texture2D() for GLSL 4.60
 */
float getAmbientOcclusion() {
    float rawAO = texture(aoMap, vAoMapUv).r;
    return (rawAO - 1.0) * aoMapIntensity + 1.0;
}

/**
 * Applies AO to the various light components.
 * Pass in your calculated light and geometry variables.
 */
void applyAO(
    float ao, 
    inout vec3 indirectDiffuse, 
    inout vec3 indirectSpecular,
    vec3 geometryNormal,
    vec3 geometryViewDir
) {
    indirectDiffuse *= ao;

    // If using CLEARCOAT or SHEEN, you would apply it here as well:
    // clearcoatSpecularIndirect *= ao;
    // sheenSpecularIndirect *= ao;

    // Standard PBR Specular Occlusion
    float dotNV = clamp(dot(geometryNormal, geometryViewDir), 0.0, 1.0);
    
    // Note: computeSpecularOcclusion must be defined in your PBR math library
    indirectSpecular *= computeSpecularOcclusion(dotNV, ao, roughness);
}
