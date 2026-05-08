
/**
 * UV Declarations - Vertex Stage
 * Attributes (Inputs) and Varyings (Outputs).
 */

// Mesh Attributes
layout(location = 29) in vec2 uv;  // Primary UV
layout(location = 30) in vec2 uv2; // Secondary UV

// Output Varyings - Synced to Fragment Input Locations
layout(location = 0)  out vec2 vAlphaMapUv;
layout(location = 1)  out vec2 vAoMapUv;
layout(location = 2)  out vec2 vBumpMapUv;
layout(location = 3)  out vec2 vClearcoatNormalMapUv;
layout(location = 4)  out vec2 vEmissiveMapUv;
layout(location = 5) out vec2 vSpecularColorMapUv;
layout(location = 6) out vec2 vSheenColorMapUv;
layout(location = 7) out vec2 vAnisotropyMapUv;
layout(location = 8) out vec2 vUv;
layout(location = 9) out vec2 vMapUv;
layout(location = 10) out vec2 vMetalnessMapUv;
layout(location = 11) out vec2 vNormalMapUv;
layout(location = 12) out vec2 vRoughnessMapUv;
layout(location = 13) out vec2 vSpecularMapUv;
layout(location = 14) out vec2 vTransmissionMapUv;
layout(location = 15) out vec2 vThicknessMapUv;
layout(location = 16) out vec2 vLightMapUv;
layout(location = 17) out vec2 vClearcoatMapUv;
layout(location = 18) out vec2 vClearcoatRoughnessMapUv;
layout(location = 19) out vec2 vIridescenceMapUv;
layout(location = 20) out vec2 vIridescenceThicknessMapUv;
layout(location = 21) out vec2 vSheenRoughnessMapUv;
layout(location = 22) out vec2 vSpecularIntensityMapUv;
layout(location = 23) out vec2 vAnisotropyVectorMapUv;

// Binding 1: Material Uniforms (UBO)
layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... all other PBR uniforms ...
    mat3 mapTransform;
    mat3 alphaMapTransform;
    mat3 lightMapTransform;
    mat3 aoMapTransform;
    mat3 bumpMapTransform;
    mat3 normalMapTransform;
    mat3 displacementMapTransform;
    mat3 emissiveMapTransform;
    mat3 metalnessMapTransform;
    mat3 roughnessMapTransform;
    mat3 anisotropyMapTransform;
    mat3 clearcoatMapTransform;
    mat3 clearcoatNormalMapTransform;
    mat3 clearcoatRoughnessMapTransform;
    mat3 sheenColorMapTransform;
    mat3 sheenRoughnessMapTransform;
    mat3 iridescenceMapTransform;
    mat3 iridescenceThicknessMapTransform;
    mat3 specularMapTransform;
    mat3 specularColorMapTransform;
    mat3 specularIntensityMapTransform;
    mat3 transmissionMapTransform;
    mat3 thicknessMapTransform;
};
