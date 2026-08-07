layout(std140, binding = 0) uniform WCALBlock {

} sblock;

in vec3 position;
in vec3 displacement;
in vec3 customColor;
out vec3 vColor;

void main() {
  vec3 newPosition = position + displacement.w * displacement.xyz;

  vColor = customColor.xyz;

  gl_Position = projectionMatrix * modelViewMatrix * vec4( newPosition, 1.0 );
  gl_Position.z *= 0.995;
}