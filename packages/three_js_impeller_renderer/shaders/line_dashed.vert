#include <material_block.glsl>
#include <instancing.glsl>

in vec3 position;
in vec2 uv; // Pull in standard geometry attributes UV layout channel 
in vec3 color;

in float instanceID;

out vec3 v_color;
out float vLineDistance;
out vec3 v_worldPosition;

void main() {
  mat4 instanceModelMatrix = getBatchingInstance(instanceID);
  vec3 vertexColor = getInstanceColor(color,instanceID);
  
  vec4 worldPosition = material.modelMatrix * instanceModelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  
  vec4 clipPosition = material.projectionMatrix * material.viewMatrix * worldPosition;
  gl_Position = clipPosition;

  float materialScale = material.lineExtendedParams.y; // line.scale uniform property slider
  if (materialScale <= 0.0) {
      materialScale = 1.0;
  }
  
  vLineDistance = uv.x * materialScale;
  v_color = material.baseColor.rgb * vertexColor;
}
