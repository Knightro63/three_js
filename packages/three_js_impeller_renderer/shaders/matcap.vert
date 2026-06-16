#include <common.glsl>

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

  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;

  v_worldNormal = normalize(mat3(material.modelMatrix) * normal);

  gl_Position = scene.projectionMatrix * scene.viewMatrix * worldPosition;

  v_color = material.baseColor.rgb * vertexColor;
  
  v_uv = uv;//vec2(position.x, position.y); // Fallback if attribute uv isn't declared
}
