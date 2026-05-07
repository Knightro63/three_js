#version 460 core

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    vec3 diffuse;
    float opacity;
    float uAlphaTest;
    bool useMap;
    bool useAlphaMap;
    bool useNormalMap;
    bool useMatcap; // SPIR-V branching
};

// Bindings
layout(binding = 60) uniform sampler2D map;
layout(binding = 2)  uniform sampler2D alphaMap;
layout(binding = 27) uniform sampler2D normalMap;
layout(binding = 62) uniform sampler2D matcap; // New slot for Matcap

// Inputs (Synced with Master List)
layout(location = 3)  in vec3 vNormal;         
layout(location = 13) in vec3 vViewPosition;   
layout(location = 8)  in vec4 vColor;          
layout(location = 23) in vec2 vMapUv;          
layout(location = 1)  in vec2 vAlphaMapUv;     
layout(location = 27) in vec2 vNormalMapUv;    

// Output 54
layout(location = 54) out vec4 pc_fragColor;

void main() {
    vec4 diffuseColor = vec4(diffuse, opacity);
    diffuseColor *= vColor;

    if (useMap) diffuseColor *= texture(map, vMapUv);
    if (useAlphaMap) diffuseColor.a *= texture(alphaMap, vAlphaMapUv).g;
    if (diffuseColor.a < uAlphaTest) discard;

    // Normal math (simplified for template)
    vec3 normal = normalize(vNormal);
    
    // Matcap UV generation logic
    vec3 viewDir = normalize(vViewPosition);
    vec3 x = normalize(vec3(viewDir.z, 0.0, -viewDir.x));
    vec3 y = cross(viewDir, x);
    vec2 uv = vec2(dot(x, normal), dot(y, normal)) * 0.495 + 0.5;

    vec4 matcapColor;
    if (useMatcap) {
        matcapColor = texture(matcap, uv);
    } else {
        matcapColor = vec4(vec3(mix(0.2, 0.8, uv.y)), 1.0);
    }

    vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;

    pc_fragColor = vec4(outgoingLight, diffuseColor.a);
}
