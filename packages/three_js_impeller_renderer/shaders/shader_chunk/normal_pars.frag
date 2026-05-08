
/**
 * Location 3: Interpolated view-space normal.
 */
layout(location = 3) in vec3 vNormal;

/**
 * Locations 25 & 26: Tangent and Bitangent basis.
 * Sequential after vMetalnessMapUv (24).
 */
layout(location = 25) in vec3 vTangent;
layout(location = 26) in vec3 vBitangent;
