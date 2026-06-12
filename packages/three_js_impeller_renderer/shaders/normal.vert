// Pull in the unified master uniform block structure under binding = 0
#include <common.glsl>

// material.normal.vertex.input (Vulkan attribute layout slots)
in vec3 position;
in vec3 normal;
in vec3 color;

// NormalVertexOutput (Interpolated outputs passed down to the fragment shader)
out vec3 v_color;
out vec3 v_normal;
out vec3 v_worldNormal;   // Passed forward to location(2)
out vec3 v_worldPosition; // Passed forward to location(3)

void main() {
  // Compute transformations via the unified uniforms block
  vec4 worldPosition = material.modelMatrix * vec4(position, 1.0);
  v_worldPosition = worldPosition.xyz;
  
  // Core Vulkan pipeline position terminal assignment output
  gl_Position = scene.projectionMatrix * scene.viewMatrix * worldPosition;
  
  // Pass the raw normalized world space vectors down to the fragment stage
  v_worldNormal = normalize((material.modelMatrix * vec4(normal, 0.0)).xyz);
  v_normal = normal;
  v_color = color;
}
