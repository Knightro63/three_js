#include <material_block.glsl>

in vec3 position;
in vec3 color;

out vec3 v_color;
out vec3 v_worldPosition;
out vec2 v_uv;

void main() {
  vec3 vertexColor = color;
  if (dot(vertexColor, vertexColor) <= 0.0) {
    vertexColor = vec3(1.0);
  }

  v_uv = vec2(position.x + 0.5, position.y + 0.5);

  vec4 worldPositionCenter = material.modelMatrix * vec4(0.0, 0.0, 0.0, 1.0);
  vec4 mvPosition = material.viewMatrix * worldPositionCenter;

  float scaleX = length(material.modelMatrix[0].xyz);
  float scaleY = length(material.modelMatrix[1].xyz);
  
  vec3 alignedPosition = mvPosition.xyz + vec3(position.x * scaleX, position.y * scaleY, 0.0);
  gl_Position = material.projectionMatrix * vec4(alignedPosition, 1.0);
  gl_Position.z = gl_Position.z * 0.995;

  v_worldPosition = worldPositionCenter.xyz + vec3(position.x * scaleX, position.y * scaleY, 0.0);
  v_color = material.baseColor.rgb * vertexColor;
}
