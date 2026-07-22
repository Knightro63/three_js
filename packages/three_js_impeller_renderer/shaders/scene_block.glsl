layout(std140, binding = 1) uniform SceneBlock {
  mat4 bgMapRotation; //backgroundMapRotation,
  mat4 envMapRotation; //envMapRotation,
  vec4 bgMapParms; //x intensity, y flip, z envTypeCube, w blurriness
  vec4 envParms; //x intensity, y flip, z envTypeCube, w lightCount
  vec4 rendParms; // x tonemapping, y exposure, colorspace
  vec4 fogColor;
  vec4 fogParams;         // near, far, density, isFogExp2

  vec4 lightPositions[16];
  vec4 lightColors[16];
  vec4 lightAttenuationParams[16];
  vec4 lightExtendedParams[16];
} scene;
