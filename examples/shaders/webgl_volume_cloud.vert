layout(std140, binding = 0) uniform WebglVertBlock {
  mat4 modelMatrix;
  mat4 modelViewMatrix;
  mat4 projectionMatrix;
  vec4 cameraPos;
} sblock;

in vec3 position;

out vec3 vOrigin;
out vec3 vDirection;

void main() {
  vec4 mvPosition = sblock.modelViewMatrix * vec4( position, 1.0 );

  vOrigin = vec3( inverse( sblock.modelMatrix ) * sblock.cameraPos).xyz;
  vDirection = position - vOrigin;

  gl_Position = sblock.projectionMatrix * mvPosition;
  gl_Position.z *= 0.995;
}