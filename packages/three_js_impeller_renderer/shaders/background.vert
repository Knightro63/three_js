#include <material_block.glsl>

in vec3 position;
in vec2 uv;

out vec2 v_uv;

void main() {
  mat3 uvTransform = mat3(
    material.modelMatrix[0].xyz, // Column 0
    material.modelMatrix[1].xyz, // Column 1
    material.modelMatrix[3].xyz  // Column 3 (Holds our clean translation properties)
  );
  
  v_uv = ( uvTransform * vec3( uv, 1.0 ) ).xy;
  gl_Position = vec4( position.xy, 1.0, 1.0 );
  gl_Position.z = gl_Position.z * 0.999;
}