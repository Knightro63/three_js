#include <common.glsl>

in vec3 position;
in vec2 uv; // Added to match lineDashed layout, preventing descriptor crashes!
in vec3 color;

out vec3 v_color;
out vec3 v_worldPosition;
out vec2 v_uv;

void main() {
  vec3 vertexColor = color;
  if (length(vertexColor) <= 0.0) {
    vertexColor = vec3(1.0);
  }

  v_uv = uv; // Pass through cleanly to satisfy the interpolation pipeline

  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  gl_Position = scene.projectionMatrix * scene.viewMatrix * worldPosition;

  v_color = material.baseColor.rgb * vertexColor;
}
