#version 460 core

// Binding 0: FrameUniforms
layout(std140, binding = 0) uniform FrameUniforms {
    mat4 uModelViewProjection;
    mat4 uModelMatrix;
    float uTime;
    vec2 uResolution;
};

// Binding 1: MaterialUniforms
layout(std140, binding = 1) uniform MaterialUniforms {
    bool useEnvMap;
    bool useSkinning;
};

// Stage Inputs
layout(location = 0)  in vec3 inPosition;
layout(location = 1)  in vec3 inNormal;
layout(location = 4)  in vec4 color;
layout(location = 29) in vec2 inUv;
layout(location = 30) in vec2 inUv2;

// Stage Outputs (Synced with Frag Master List)
layout(location = 23) out vec2 vMapUv;         // Frag 23
layout(location = 52) out vec2 vUv2;           // Frag 52 (Shared AO/Lightmap)
layout(location = 8)  out vec4 vColor;         // Frag 8
layout(location = 3)  out vec3 vNormal;        // Frag 3
layout(location = 10) out vec3 vWorldPosition; // Frag 10 (for EnvMap)

void main() {
    vMapUv = inUv;
    vUv2 = inUv2;
    vColor = color;

    vec3 transformedNormal = inNormal;
    vec4 worldPosition = uModelMatrix * vec4(inPosition, 1.0);
    
    // SPIR-V branching for Normals (EnvMap requirement)
    if (useEnvMap || useSkinning) {
        // Simple world normal transform (non-uniform scale not handled for Basic)
        vNormal = normalize(mat3(uModelMatrix) * transformedNormal);
    }

    vWorldPosition = worldPosition.xyz;

    // Standard projection
    gl_Position = uModelViewProjection * vec4(inPosition, 1.0);
}
