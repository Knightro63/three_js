#include <common.glsl>

in vec3 position;
in vec3 color;

out vec3 v_color;
out vec3 v_worldPosition;

void main() {
  vec3 vertexColor = color;
  if (dot(vertexColor, vertexColor) <= 0.0) {
    vertexColor = vec3(1.0);
  }

  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  gl_Position = scene.projectionMatrix * scene.viewMatrix * worldPosition;

  float pointSize = material.lineParams.x; 
  bool sizeAttenuation = material.lineParams.y > 0.5;

  if (sizeAttenuation) {
    vec4 viewPosition = scene.viewMatrix * worldPosition;
    gl_PointSize = pointSize * (material.lineParams.z / -viewPosition.z);
  } 
  else {
    gl_PointSize = pointSize;
  }

  v_color = material.baseColor.rgb * vertexColor;
}
