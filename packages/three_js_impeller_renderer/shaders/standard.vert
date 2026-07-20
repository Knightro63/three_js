#include <common.glsl>
#include <skinning.glsl>
#include <instancing.glsl>

uniform sampler2D displacementMap;

in vec3 position;
in vec3 normal;
in vec2 uv;
in vec3 color;
in vec4 skinIndex;
in vec4 skinWeight;
in float instanceID;

out vec3 v_color;
out vec3 v_worldPosition;
out vec3 v_worldNormal;
out vec2 v_uv;

void main() {
    mat4 instanceModelMatrix = mat4(1.0);
    vec3 vertexColor = color;
    
    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3(1.0);
    }

    // 1. FIXED: Correctly evaluate dynamic uniform flag channels
    bool hasInstancingTexture = material.flags5.w > 0.5;
    bool hasInstancingColor   = material.flags5.w > 1.5; // Fixed flag matching check

    if (hasInstancingTexture) {
        instanceModelMatrix = getInstanceMatrix(instanceID);
    }
    if (hasInstancingColor) {
        vertexColor = getInstanceColor(instanceID);
    }

    v_uv = uv;

    bool hasDisplacementMap = material.flags2.x > 0.5;
    bool hasBoneTexture     = material.flags0.x > 0.5;
    
    vec3 displacedPosition = position;
    vec3 animatedNormal    = normal;

    // 2. Compute Surface Displacement
    if (hasDisplacementMap) {
        float displacement = texture(displacementMap, v_uv).r;
        displacedPosition += normal * (displacement * material.materialParams.y + material.materialParams.z);
    }

    // 3. Resolve Skeletal Animation Transformations
    if (hasBoneTexture) {
        mat4 skinMatrix   = getSkinMatrix(skinIndex, skinWeight);
        displacedPosition = (skinMatrix * vec4(displacedPosition, 1.0)).xyz;
        animatedNormal    = mat3(skinMatrix) * animatedNormal;
    }

    // 4. FIXED MATRIX CHAIN: Multiply material layout parameters sequentially
    mat4 fullModelMatrix = material.modelMatrix * instanceModelMatrix;
    vec4 worldPosition4  = fullModelMatrix * vec4(displacedPosition, 1.0);
    
    v_worldPosition = worldPosition4.xyz;

    // 5. Compute Final Screen-space Clip Position
    vec4 viewPosition = scene.viewMatrix * worldPosition4;
    gl_Position       = scene.projectionMatrix * viewPosition;
    gl_Position.z     = gl_Position.z * 0.995; 

    // 6. FIXED NORMALS: Compute Inverse Transpose to support instance rotations/scaling
    mat3 normalMatrix = transpose(inverse(mat3(fullModelMatrix)));
    v_worldNormal     = normalize(normalMatrix * animatedNormal);

    v_color = material.baseColor.rgb * vertexColor;
}
