#include <common.glsl>
#include <instancing.glsl>

in vec3 position;
in vec3 color;

in float instanceID;

out vec3 v_color;
out vec3 v_worldPosition;

void main() {
  mat4 instanceModelMatrix = mat4(1.0);
  vec3 instanceColor = color;

  bool hasInstancingTexture = material.flags5.w > 0.5;
  bool hasInstancingColor = material.flags5.w > 1.5;
  if (hasInstancingTexture) {
    instanceModelMatrix = getInstanceMatrix(instanceID);
  }
  if (hasInstancingColor) {
    instanceColor = getInstanceColor(instanceID);
  }

  vec4 worldPosition = material.modelMatrix * instanceModelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  gl_Position = scene.projectionMatrix * scene.viewMatrix * worldPosition;
  gl_Position.z = gl_Position.z * 0.995;

  v_color = material.baseColor.rgb * instanceColor;
}
