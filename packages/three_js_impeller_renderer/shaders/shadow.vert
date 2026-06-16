#include <common.glsl>

in vec3 position;
in vec3 normal;
in vec3 color;

out vec3 v_color;
out vec3 v_worldPosition;
out vec3 v_worldNormal;

void main() {
  vec3 vertexColor = color;
  if (dot(vertexColor, vertexColor) <= 0.0) {
    vertexColor = vec3(1.0);
  }

  vec4 worldPosition4 = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition4.xyz;
  v_worldNormal = normalize(mat3(material.modelMatrix) * normal);

  vec4 viewPosition = scene.viewMatrix * worldPosition4;
  gl_Position = scene.projectionMatrix * viewPosition;
  v_color = material.baseColor.rgb * vertexColor;
}
