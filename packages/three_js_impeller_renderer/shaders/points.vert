#include <material_block.glsl>
#include <instancing.glsl>

in vec3 position;
in vec3 color;

in float instanceID;

out vec3 v_color;
out vec3 v_worldPosition;

void main() {
  mat4 instanceModelMatrix = getBatchingInstance(instanceID);
  vec3 vertexColor = getInstanceColor(color,instanceID);

  vec4 worldPosition = material.modelMatrix * instanceModelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  gl_Position = material.projectionMatrix * material.viewMatrix * worldPosition;
  gl_Position.z = gl_Position.z * 0.995;

  float pointSize = material.lineParams.x; 
  bool sizeAttenuation = material.lineParams.y > 0.5;

  if (sizeAttenuation) {
    vec4 viewPosition = material.viewMatrix * worldPosition;
    gl_PointSize = pointSize * (material.lineParams.z / -viewPosition.z);
  } 
  else {
    gl_PointSize = pointSize;
  }

  v_color = material.baseColor.rgb * vertexColor;
}
