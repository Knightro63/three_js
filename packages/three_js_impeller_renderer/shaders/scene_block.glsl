layout(std140, binding = 1) uniform SceneBlock { 
  mat4 bgMapRotation; 
  mat4 envMapRotation; 
  
  vec4 bgMapParms;             // x: intensity, y: flip, z: envTypeCube, w: blurriness
  vec4 envParms;               // x: intensity, y: flip, z: envTypeCube, w: lightCount
  vec4 rendParms;              // x: tonemapping, y: exposure, z: colorspace
  vec4 fogColor; 
  vec4 fogParams;              // x: near, y: far, z: density, w: isFogExp2
  
  vec4 lightPositions[16]; 
  vec4 lightColors[16]; 
  vec4 lightAttenuationParams[16]; 
  vec4 lightExtendedParams[16]; 
  
  // Each mat4 consumes 4 vec4 registers under std140 rules (16 floats * 16 matrices = 256 floats)
  mat4 lightSpaceMatrices[16]; 
} scene;
