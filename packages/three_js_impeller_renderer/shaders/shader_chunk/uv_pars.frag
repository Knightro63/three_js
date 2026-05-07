#version 460 core

/**
 * UV Declarations - Fragment Stage
 * Mapped to the specific locations established in the Master List.
 */

// Primary UVs
#version 460 core

// 1. Established Base UVs (from your Master List)
layout(location = 1)  in vec2 vAlphaMapUv;
layout(location = 2)  in vec2 vAoMapUv;
layout(location = 5)  in vec2 vBumpMapUv;
layout(location = 6)  in vec2 vClearcoatNormalMapUv;
layout(location = 9)  in vec2 vEmissiveMapUv;
layout(location = 18) in vec2 vSpecularColorMapUv;
layout(location = 19) in vec2 vSheenColorMapUv;
layout(location = 20) in vec2 vAnisotropyMapUv;
layout(location = 23) in vec2 vMapUv;
layout(location = 24) in vec2 vMetalnessMapUv;
layout(location = 27) in vec2 vNormalMapUv;
layout(location = 28) in vec2 vRoughnessMapUv;
layout(location = 41) in vec2 vSpecularMapUv;
layout(location = 42) in vec2 vTransmissionMapUv;
layout(location = 43) in vec2 vThicknessMapUv;

// 2. New Unique Locations for the remaining UVs (Starting at 44)
layout(location = 44) in vec2 vLightMapUv;
layout(location = 45) in vec2 vClearcoatMapUv;
layout(location = 46) in vec2 vClearcoatRoughnessMapUv;
layout(location = 47) in vec2 vIridescenceMapUv;
layout(location = 48) in vec2 vIridescenceThicknessMapUv;
layout(location = 49) in vec2 vSheenRoughnessMapUv;
layout(location = 50) in vec2 vSpecularIntensityMapUv;
layout(location = 51) in vec2 vAnisotropyVectorMapUv; // For the vector itself if needed

layout(set = 0, binding = 1) uniform MaterialUniforms {
    // ... previous uniforms
    mat3 transmissionMapTransform;
    mat3 thicknessMapTransform;
};
