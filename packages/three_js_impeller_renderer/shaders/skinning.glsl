layout(binding = 2) uniform sampler2D boneTexture;

mat4 getBoneMatrix(float i) {
  // We pull the pre-calculated texture size directly from our Dart uniforms block.
  float size = material.boneTextureParm.x; 
  if (size <= 0.0) size = 4.0; // Safety guard against division-by-zero
  
  int j = int(i) * 4;
  float yPixel = floor(float(j) / size);
  float xPixel = mod(float(j), size);
  
  // Convert matrix texel coordinates to exact normalized center points
  vec2 uv1 = vec2(xPixel + 0.5, yPixel + 0.5) / size;
  vec2 uv2 = vec2(xPixel + 1.5, yPixel + 0.5) / size;
  vec2 uv3 = vec2(xPixel + 2.5, yPixel + 0.5) / size;
  vec2 uv4 = vec2(xPixel + 3.5, yPixel + 0.5) / size;
  
  // Normal floating-point texture sampling works perfectly in impellerc
  vec4 v1 = texture(boneTexture, uv1);
  vec4 v2 = texture(boneTexture, uv2);
  vec4 v3 = texture(boneTexture, uv3);
  vec4 v4 = texture(boneTexture, uv4);
  
  return mat4(v1, v2, v3, v4);
}


mat4 getSkinMatrix(vec4 skinIndex, vec4 skinWeight) {
  // Pull the structural mesh spacing uniforms passed from Dart
  mat4 bindMatrix = material.bindMatrices[0];
  mat4 bindMatrixInverse = material.bindMatrices[1];
  
  // Fetch the 4 active influencing bone transformations
  mat4 boneMatX = getBoneMatrix(skinIndex.x);
  mat4 boneMatY = getBoneMatrix(skinIndex.y);
  mat4 boneMatZ = getBoneMatrix(skinIndex.z);
  mat4 boneMatW = getBoneMatrix(skinIndex.w);
  
  // Build a unified skeletal projection matrix
  mat4 skinMatrix = 
      boneMatX * skinWeight.x +
      boneMatY * skinWeight.y +
      boneMatZ * skinWeight.z +
      boneMatW * skinWeight.w;
      
  // Combine the skeleton sequence with the base space offsets
  return bindMatrixInverse * skinMatrix * bindMatrix;
}

vec4 getSkinPosition(vec4 skinIndex, vec4 skinWeight, vec3 position) {
  return getSkinMatrix(skinIndex,skinWeight) * vec4(position,1.0);
}