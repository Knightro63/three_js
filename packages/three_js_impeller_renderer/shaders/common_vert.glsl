layout(std140, binding = 0) uniform VertexBlock {
  mat4 modelMatrix;
  mat4 viewMatrix;
  mat4 projectionMatrix;
  vec4 textureParm; //bone,instance,displace
} vert;