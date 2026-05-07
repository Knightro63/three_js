#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    vec3 emissive;
    vec3 specular;
    float shininess;
    float opacity;
    float uAlphaTest;
    float aoMapIntensity;
    float lightMapIntensity;
    bool useMap;
    bool useAlphaMap;
    bool useEmissiveMap;
    bool useAoMap;
    bool useLightMap;
    bool useSpecularMap;
    bool useNormalMap;
    bool useBumpMap;
};

// Bindings per Master List
layout(binding = 60) uniform sampler2D map;
layout(binding = 2)  uniform sampler2D alphaMap;
layout(binding = 12) uniform sampler2D emissiveMap;
layout(binding = 3)  uniform sampler2D aoMap;
layout(binding = 16) uniform sampler2D lightMap;
layout(binding = 54) uniform sampler2D specularMap;
layout(binding = 27) uniform sampler2D normalMap;
layout(binding = 5)  uniform sampler2D bumpMap;

// Inputs (Synced with Master List)
layout(location = 3)  in vec3 vNormal;         
layout(location = 13) in vec3 vViewPosition;   
layout(location = 8)  in vec4 vColor;          
layout(location = 23) in vec2 vMapUv;          
layout(location = 1)  in vec2 vAlphaMapUv;     
layout(location = 9)  in vec2 vEmissiveMapUv;  
layout(location = 2)  in vec2 vAoMapUv;        
layout(location = 44) in vec2 vLightMapUv;     
layout(location = 41) in vec2 vSpecularMapUv;  
layout(location = 27) in vec2 vNormalMapUv;    
layout(location = 5)  in vec2 vBumpMapUv;

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

    // Phong Lighting logic (Simplified for template)
    // ReflectedLight components (directDiffuse, indirectDiffuse, directSpecular, indirectSpecular)
    vec3 indirectDiffuse = vec3(1.0); 
    if (useLightMap) indirectDiffuse = texture(lightMap, vLightMapUv).rgb * lightMapIntensity;

    if (useAoMap) {
        float ambientOcclusion = (texture(aoMap, vAoMapUv).r - 1.0) * aoMapIntensity + 1.0;
        indirectDiffuse *= ambientOcclusion;
    }

    // In a full implementation, lights_phong_fragment logic would iterate through 
    // light bindings (29, 33, 37) to calculate directSpecular and directDiffuse.

    vec3 outgoingLight = (indirectDiffuse * diffuseColor.rgb) + totalEmissiveRadiance;

    pc_fragColor = vec4(outgoingLight, diffuseColor.a);
}
