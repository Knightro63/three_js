#include <material_block.glsl>
#include <instancing.glsl>

in vec3 position;
in vec2 uv;
in vec3 color;
in float lineDistance;

in float instanceID;

out vec3 v_color;
out float v_lineDistance;
out vec3 v_worldPosition;
out vec2 v_uv;

void main() {
  float materialScale = material.lineExtendedParams.y;
  if (materialScale <= 0.0) {
    materialScale = 1.0;
  }
  v_lineDistance =  lineDistance * materialScale;

  v_uv = uv;
  v_color = getInstanceColor(color,instanceID) * material.baseColor.rgb;
  mat4 instanceModelMatrix = getBatchingInstance(instanceID);
  
  vec4 worldPosition = material.modelMatrix * instanceModelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  
  vec4 viewPosition = material.viewMatrix * worldPosition;
  gl_Position  = material.projectionMatrix * viewPosition;
  gl_Position.z = gl_Position.z * 0.995; // Custom depth adjustments
}
