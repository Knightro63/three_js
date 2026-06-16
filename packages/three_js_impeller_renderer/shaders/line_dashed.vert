#include <common.glsl>

in vec3 position;
in vec2 uv; // Pull in standard geometry attributes UV layout channel 
in vec3 color;

out vec3 v_color;
out float vLineDistance;
out vec3 v_worldPosition;

void main() {
  vec3 vertexColor = color;
  if (dot(vertexColor, vertexColor) <= 0.0) {
    vertexColor = vec3(1.0);
  }

  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  
  // Project vertices cleanly into final clipping screen coordinates
  vec4 clipPosition = scene.projectionMatrix * scene.viewMatrix * worldPosition;
  gl_Position = clipPosition;

  // THE GPU CORRECTION: 
  // Instead of trusting hardware vertex lineDistance streams, we map the dash tracker 
  // to the texture mapping UV coordinates scaled directly by your material line scale uniform!
  float materialScale = material.lineExtendedParams.y; // line.scale uniform property slider
  if (materialScale <= 0.0) {
      materialScale = 1.0;
  }
  
  // Multiply the UV horizontal coordinate by your scale factor to drive the fragment loop
  vLineDistance = uv.x * materialScale;
  
  v_color = material.baseColor.rgb * vertexColor;
}
