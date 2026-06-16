#include <common.glsl>

in vec3 position;
in vec2 uv;
in vec3 color;

out vec3 v_color;
out vec3 v_worldPosition;
out vec2 v_uv;

void main() {
  vec3 vertexColor = color;
  if (dot(vertexColor, vertexColor) <= 0.0) {
    vertexColor = vec3(1.0);
  }

  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  gl_Position = scene.projectionMatrix * scene.viewMatrix * worldPosition;

  float pointSize = material.materialParams.x; 
  // bool sizeAttenuation = material.flags1.x > 0.5;

  // if (sizeAttenuation) {
  //   vec4 viewPosition = scene.viewMatrix * worldPosition;
  //   gl_PointSize = pointSize * (300.0 / -viewPosition.z);
  // } 
  // else {
    gl_PointSize = pointSize;
  // }

  v_color = material.baseColor.rgb * vertexColor;
  v_uv = uv;
}
