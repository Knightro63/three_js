#include <common.glsl>
#include <skinning.glsl>   // Provides your getSkinPosition / bone chunks
#include <instancing.glsl> // Provides your getInstanceMatrix(id) helper

in vec3 position;
in vec3 normal;

in vec4 skinIndex;
in vec4 skinWeight;

in float instanceID;

out vec3 v_worldNormal;
out vec3 v_worldPosition;

void main() {
    mat4 instanceModelMatrix = mat4(1.0);
    vec4 skinPosition = vec4(position, 1.0);
    vec3 skinNormal = normal;

    bool hasInstancingTexture = material.flags5.w > 0.5;
    bool hasBoneTexture = material.flags0.x > 0.5; // Double check your uniform flags

    // 1. SKINNING FIRST: Calculate bone deformations in local mesh space
    if (hasBoneTexture) {
        mat4 skinMatrix = getSkinMatrix(skinIndex, skinWeight);
        
        // Transform the local vertex coordinates
        skinPosition = skinMatrix * vec4(position, 1.0);
        
        // Transform the local vertex normals (using the upper 3x3 of the skin matrix)
        skinNormal = mat3(skinMatrix) * normal;    
    }

    // 2. INSTANCING SECOND: Resolve your instance matrix from the texture rows
    if (hasInstancingTexture) {
        instanceModelMatrix = getInstanceMatrix(instanceID);
    }

    // 3. COMBINE TRANSFORMS: Local -> Animated Local -> Instanced World
    mat4 fullModelMatrix = material.modelMatrix * instanceModelMatrix;
    
    vec4 worldPosition = fullModelMatrix * skinPosition;
    v_worldPosition = worldPosition.xyz;
    
    gl_Position = scene.projectionMatrix * scene.viewMatrix * worldPosition;
    gl_Position.z = gl_Position.z * 0.995;

    // 4. TRANSFORM NORMALS ACCURATELY: Handles skeleton deformation and instance orientation
    mat3 normalMatrix = transpose(inverse(mat3(fullModelMatrix)));
    v_worldNormal = normalize(normalMatrix * skinNormal);
}
