#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
    float uAlphaTest;
    float aoMapIntensity;
    float lightMapIntensity;
    bool isFlatShaded;      // SPIR-V branching for #ifndef FLAT_SHADED
    bool useMap;
    bool useAlphaMap;
    bool useAlphaHash;
    bool useAoMap;
    bool useLightMap;
    bool useSpecularMap;
    bool useEnvMap;
};

// Bindings per Master List
layout(binding = 60) uniform sampler2D map;        // Using 60 for Basic/Depth Diffuse
layout(binding = 2)  uniform sampler2D alphaMap;   // Binding 2
layout(binding = 3)  uniform sampler2D aoMap;      // Binding 3
layout(binding = 16) uniform sampler2D lightMap;   // Binding 16
layout(binding = 54) uniform sampler2D specularMap;// Binding 54
layout(binding = 10) uniform sampler2D envMap;     // Binding 10

// Fragment Inputs per Master List
layout(location = 3)  in vec3 vNormal;             // Normal for lighting
layout(location = 8)  in vec4 vColor;              // Interpolated vertex color
layout(location = 23) in vec2 vMapUv;              // Primary UV
layout(location = 1)  in vec2 vAlphaMapUv;         // Alpha UV
layout(location = 2)  in vec2 vAoMapUv;            // AO UV
layout(location = 44) in vec2 vLightMapUv;         // Lightmap UV
layout(location = 41) in vec2 vSpecularMapUv;      // Specular UV

// Final Output
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);

    // Color Attribute
    diffuseColor *= vColor;

    // Map logic
    if (useMap) {
        diffuseColor *= texture(map, vMapUv);
    }

    // Alpha Map/Test logic
    if (useAlphaMap) {
        diffuseColor.a *= texture(alphaMap, vAlphaMapUv).g;
    }
    if (diffuseColor.a < uAlphaTest) discard;

    // Lighting logic
    vec3 indirectDiffuse = vec3(0.0);
    if (useLightMap) {
        vec4 lightMapTexel = texture(lightMap, vLightMapUv);
        indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * 0.31830988618; // RECIPROCAL_PI
    } else {
        indirectDiffuse += vec3(1.0);
    }

    // AO Map
    if (useAoMap) {
        float ambientOcclusion = (texture(aoMap, vAoMapUv).r - 1.0) * aoMapIntensity + 1.0;
        indirectDiffuse *= ambientOcclusion;
    }

    // Specular Map
    if (useSpecularMap) {
        float specularStrength = texture(specularMap, vSpecularMapUv).r;
        indirectDiffuse *= specularStrength; 
    }

    vec3 outgoingLight = indirectDiffuse * diffuseColor.rgb;

    // Environment Map (Simplified for Basic)
    if (useEnvMap) {
        // Sample envMap logic here
    }

    pc_fragColor = vec4(outgoingLight, diffuseColor.a);
}
