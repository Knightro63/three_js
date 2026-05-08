
/**
 * Stage: Vertex
 * Applying mat3 transforms to raw UV attributes.
 */

// Attributes (Inputs) - Starting after skinWeight (28)
layout(location = 29) in vec2 inUv;  // Primary UV set
layout(location = 30) in vec2 inUv2; // Secondary UV set (AO, Light, etc.)

// Output Locations - Synced with Fragment Inputs
layout(location = 1)  out vec2 vAlphaMapUv;
layout(location = 2)  out vec2 vAoMapUv;
layout(location = 5)  out vec2 vBumpMapUv;
layout(location = 6)  out vec2 vClearcoatNormalMapUv;
layout(location = 9)  out vec2 vEmissiveMapUv;
layout(location = 18) out vec2 vSpecularColorMapUv;
layout(location = 19) out vec2 vSheenColorMapUv;
layout(location = 20) out vec2 vAnisotropyMapUv;
layout(location = 23) out vec2 vMapUv;
layout(location = 24) out vec2 vMetalnessMapUv;
layout(location = 27) out vec2 vNormalMapUv;
layout(location = 28) out vec2 vRoughnessMapUv;
layout(location = 41) out vec2 vSpecularMapUv;
layout(location = 42) out vec2 vTransmissionMapUv;
layout(location = 43) out vec2 vThicknessMapUv;
layout(location = 44) out vec2 vLightMapUv;
layout(location = 45) out vec2 vClearcoatMapUv;
layout(location = 46) out vec2 vClearcoatRoughnessMapUv;
layout(location = 47) out vec2 vIridescenceMapUv;
layout(location = 48) out vec2 vIridescenceThicknessMapUv;
layout(location = 49) out vec2 vSheenRoughnessMapUv;
layout(location = 50) out vec2 vSpecularIntensityMapUv;
layout(location = 51) out vec2 vAnisotropyVectorMapUv;

// Binding 1: Material Uniforms (UBO)
layout(set = 0, binding = 1) uniform MaterialUniforms {
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
    mat3 iridescenceMapTransform;
    mat3 iridescenceThicknessMapTransform;
    mat3 sheenColorMapTransform;
    mat3 sheenRoughnessMapTransform;
    mat3 specularMapTransform;
    mat3 specularColorMapTransform;
    mat3 specularIntensityMapTransform;
    mat3 transmissionMapTransform;
    mat3 thicknessMapTransform;
};

void applyUVTransforms() {
    // Standard UV 1 transforms
    vMapUv = (mapTransform * vec3(inUv, 1.0)).xy;
    vBumpMapUv = (bumpMapTransform * vec3(inUv, 1.0)).xy;
    vNormalMapUv = (normalMapTransform * vec3(inUv, 1.0)).xy;
    vEmissiveMapUv = (emissiveMapTransform * vec3(inUv, 1.0)).xy;
    vMetalnessMapUv = (metalnessMapTransform * vec3(inUv, 1.0)).xy;
    vRoughnessMapUv = (roughnessMapTransform * vec3(inUv, 1.0)).xy;
    vAnisotropyMapUv = (anisotropyMapTransform * vec3(inUv, 1.0)).xy;
    vSpecularMapUv = (specularMapTransform * vec3(inUv, 1.0)).xy;
    vSpecularColorMapUv = (specularColorMapTransform * vec3(inUv, 1.0)).xy;
    vSpecularIntensityMapUv = (specularIntensityMapTransform * vec3(inUv, 1.0)).xy;
    
    // UV 2 transforms
    vAlphaMapUv = (alphaMapTransform * vec3(inUv2, 1.0)).xy;
    vAoMapUv = (aoMapTransform * vec3(inUv2, 1.0)).xy;
    vLightMapUv = (lightMapTransform * vec3(inUv2, 1.0)).xy;

    // Transmission/Volume
    vTransmissionMapUv = (transmissionMapTransform * vec3(inUv, 1.0)).xy;
    vThicknessMapUv = (thicknessMapTransform * vec3(inUv, 1.0)).xy;

    // Clearcoat
    vClearcoatMapUv = (clearcoatMapTransform * vec3(inUv, 1.0)).xy;
    vClearcoatNormalMapUv = (clearcoatNormalMapTransform * vec3(inUv, 1.0)).xy;
    vClearcoatRoughnessMapUv = (clearcoatRoughnessMapTransform * vec3(inUv, 1.0)).xy;

    // Iridescence / Sheen
    vIridescenceMapUv = (iridescenceMapTransform * vec3(inUv, 1.0)).xy;
    vIridescenceThicknessMapUv = (iridescenceThicknessMapTransform * vec3(inUv, 1.0)).xy;
    vSheenColorMapUv = (sheenColorMapTransform * vec3(inUv, 1.0)).xy;
    vSheenRoughnessMapUv = (sheenRoughnessMapTransform * vec3(inUv, 1.0)).xy;
}
