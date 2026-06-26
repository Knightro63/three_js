#include <common.glsl>

uniform sampler2D displacementMap;

// Incoming Vertex Stream Layout Attributes
in vec3 position;
in vec3 normal;
in vec2 uv;
in vec3 color;

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
  vec3 displacedPosition = position;

  if (hasDisplacementMap) {
    float displacement = texture(displacementMap, v_uv).r;
    displacedPosition += normal * (displacement * material.materialParams.y + material.materialParams.z);
  }

  vec4 worldPosition4 = material.modelMatrix * vec4(displacedPosition, 1.0);
  v_worldPosition = worldPosition4.xyz;
  
  v_worldNormal = normalize(mat3(material.modelMatrix) * normal);

  vec4 viewPosition = scene.viewMatrix * worldPosition4;
  gl_Position = scene.projectionMatrix * viewPosition;
  gl_Position.z = gl_Position.z * 0.995;

  v_color = material.baseColor.rgb * vertexColor;
}
