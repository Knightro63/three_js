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
  vec3 localPosition = position;
  vec3 localNormal = normal;

  if (dot(vertexColor, vertexColor) <= 0.0) {
    vertexColor = vec3(1.0);
  }

  // 1. Resolve Instancing Matrix and Colors
  bool hasInstancingTexture = material.flags5.w > 0.5;
  bool hasInstancingColor   = material.flags5.w > 1.5;

  if (hasInstancingTexture) {
    instanceModelMatrix = getInstanceMatrix(instanceID);
  }
  if (hasInstancingColor) {
    vertexColor = getInstanceColor(instanceID);
  }

  v_uv = uv;

  // 2. Resolve Vertex Displacement Maps (if applicable)
  bool hasDisplacementMap = material.flags1.x > 0.5;
  if (hasDisplacementMap) {
    float displacement = texture(displacementMap, v_uv).r;
    localPosition += normal * (displacement * material.materialParams.y + material.materialParams.z);
  }

  // 3. Resolve Skeletal Bone Skinning or Morph Targets
  bool hasMorphTexture = material.flags0.x > 1.5;
  bool hasBoneTexture  = material.flags0.x > 0.5;
  
    // Declare the master unified coordinate matrix
    mat4 fullModelMatrix = material.modelMatrix * instanceModelMatrix;
    vec4 worldPosition4;

  if (hasMorphTexture) {
    // --- MORPH TARGET BLENDING PATH ---
    vec3 morphDelta = getMorphTargetOffset(float(gl_VertexIndex));
    localPosition += morphDelta;

    worldPosition4 = fullModelMatrix * vec4(localPosition, 1.0);
    
    mat3 normalMatrix = transpose(inverse(mat3(fullModelMatrix)));
    localNormal = normalize(normalMatrix * localNormal);

  } else if (hasBoneTexture) {
    // --- SKELETAL SKINNING PATH ---
    mat4 skinMatrix = getSkinMatrix(skinIndex, skinWeight);

    // FIXED MULTIPLICATION ORDER: Master Group -> Individual Instance -> Skeletal Bone -> Vertices
    worldPosition4 = fullModelMatrix * skinMatrix * vec4(localPosition, 1.0);

    // Compute accurate normal rotations across the absolute combined layout chain
    mat3 normalMatrix = transpose(inverse(mat3(fullModelMatrix * skinMatrix)));
    localNormal = normalize(normalMatrix * localNormal);

  } else {
    // --- STANDARD STATIC MESH PATH ---
    worldPosition4 = fullModelMatrix * vec4(localPosition, 1.0);
    
    mat3 normalMatrix = transpose(inverse(mat3(fullModelMatrix)));
    localNormal = normalize(normalMatrix * localNormal);
  }
  
  // 4. Map output positions out to fragment stages
  v_worldPosition = worldPosition4.xyz;
  v_worldNormal   = localNormal; // FIXED: Safely locks your fully transformed normal channels

  // 5. Compute Final Screen-space Clip Position
  vec4 viewPosition = scene.viewMatrix * worldPosition4;
  gl_Position       = scene.projectionMatrix * viewPosition;

  v_color = material.baseColor.rgb * vertexColor;
}
