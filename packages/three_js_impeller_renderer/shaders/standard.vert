#include <common.glsl>
#include <skinning.glsl>

layout(binding = 3) uniform sampler2D displacementMap;

in vec3 position;
in vec3 normal;
in vec2 uv;
in vec3 color;
in vec4 skinIndex;
in vec4 skinWeight;

out vec3 v_color;
out vec3 v_worldPosition;
out vec3 v_worldNormal;
out vec2 v_uv;

void main() {
    vec3 vertexColor = color;
    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3(1.0);
    }
    v_uv = uv;

    bool hasDisplacementMap = material.flags2.x > 0.5;
    bool hasBoneTexture = material.flags0.x > 0.5;
    
    vec3 displacedPosition = position;
    if (hasDisplacementMap) {
        float displacement = texture(displacementMap, v_uv).r;
        // material.materialParams.y = displacementScale, material.materialParams.z = displacementBias
        displacedPosition += normal * (displacement * material.materialParams.y + material.materialParams.z);
    }

    vec4 worldPosition4;
    vec3 animatedNormal = normal;

    if (hasBoneTexture) {
        mat4 skinMatrix = getSkinMatrix(skinIndex, skinWeight);
        worldPosition4 = skinMatrix * vec4(displacedPosition, 1.0);
        animatedNormal = mat3(skinMatrix) * normal;
    } else {
        worldPosition4 = material.modelMatrix * vec4(displacedPosition, 1.0);
    }
    v_worldPosition = worldPosition4.xyz;
    
    v_worldNormal = normalize(mat3(material.modelMatrix) * animatedNormal);

    vec4 viewPosition = scene.viewMatrix * worldPosition4;
    gl_Position = scene.projectionMatrix * viewPosition;
    
    gl_Position.z = gl_Position.z * 0.995; 

    v_color = material.baseColor.rgb * vertexColor;
}
