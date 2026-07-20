#include <common.glsl>
#include <instancing.glsl>

in vec3 position;
in vec2 uv; // Pull in standard geometry attributes UV layout channel 
in vec3 color;

in float instanceID;

out vec3 v_color;
out float vLineDistance;
out vec3 v_worldPosition;

void main() {
  mat4 instanceModelMatrix = mat4(1.0);
  vec3 vertexColor = color;
  if (dot(vertexColor, vertexColor) <= 0.0) {
    vertexColor = vec3(1.0);
  }

  bool hasInstancingTexture = material.flags5.w > 0.5;
  bool hasInstancingColor = material.flags5.w > 1.5;
  if (hasInstancingTexture) {
    instanceModelMatrix = getInstanceMatrix(instanceID);
  }
  if (hasInstancingColor) {
    vertexColor = getInstanceColor(instanceID);
  }

  vec4 worldPosition = material.modelMatrix * instanceModelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  
  vec4 clipPosition = scene.projectionMatrix * scene.viewMatrix * worldPosition;
  gl_Position = clipPosition;

  float materialScale = material.lineExtendedParams.y; // line.scale uniform property slider
  if (materialScale <= 0.0) {
      materialScale = 1.0;
  }
  
  vLineDistance = uv.x * materialScale;
  v_color = material.baseColor.rgb * vertexColor;
}
