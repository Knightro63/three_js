#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    vec3 emissive;
    float opacity;
    float uAlphaTest;
    float aoMapIntensity;
    float lightMapIntensity;
    bool useMap;
    bool useAlphaMap;
    bool useEmissiveMap;
    bool useAoMap;
    bool useLightMap;
    bool useGradientMap;
    bool useNormalMap;
};

// Bindings per Master List
layout(binding = 60) uniform sampler2D map;
layout(binding = 2)  uniform sampler2D alphaMap;
layout(binding = 12) uniform sampler2D emissiveMap;
layout(binding = 3)  uniform sampler2D aoMap;
layout(binding = 16) uniform sampler2D lightMap;
layout(binding = 13) uniform sampler2D gradientMap; // Binding 13
layout(binding = 27) uniform sampler2D normalMap;

// Inputs (Synced with Master List)
layout(location = 3)  in vec3 vNormal;         
layout(location = 13) in vec3 vViewPosition;   
layout(location = 8)  in vec4 vColor;          
layout(location = 23) in vec2 vMapUv;          
layout(location = 1)  in vec2 vAlphaMapUv;     
layout(location = 9)  in vec2 vEmissiveMapUv;  
layout(location = 2)  in vec2 vAoMapUv;        
layout(location = 44) in vec2 vLightMapUv;     
layout(location = 27) in vec2 vNormalMapUv;    

// Final Output
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);
    diffuseColor *= vColor;

    if (useMap) diffuseColor *= texture(map, vMapUv);
    if (useAlphaMap) diffuseColor.a *= texture(alphaMap, vAlphaMapUv).g;
    if (diffuseColor.a < uAlphaTest) discard;

    vec3 totalEmissiveRadiance = emissive;
    if (useEmissiveMap) totalEmissiveRadiance *= texture(emissiveMap, vEmissiveMapUv).rgb;

    // Toon Lighting logic
    vec3 indirectDiffuse = vec3(1.0); 
    if (useLightMap) indirectDiffuse = texture(lightMap, vLightMapUv).rgb * lightMapIntensity;

    if (useAoMap) {
        float ambientOcclusion = (texture(aoMap, vAoMapUv).r - 1.0) * aoMapIntensity + 1.0;
        indirectDiffuse *= ambientOcclusion;
    }

    // Gradient map logic would normally be applied during direct light accumulation
    // using the N dot L result to sample the gradientMap (Binding 13).

    vec3 outgoingLight = (indirectDiffuse * diffuseColor.rgb) + totalEmissiveRadiance;

    pc_fragColor = vec4(outgoingLight, diffuseColor.a);
}
