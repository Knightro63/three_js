layout(binding = 2) uniform sampler2D unifiedTransformationTexture;

mat4 getBoneMatrix(float i) {
  float size = material.boneTextureParm.x; // Explicit bone texture width uniform
  if (size <= 0.0) size = 4.0; 
  
  int j = int(i) * 4;
  float yPixel = floor(float(j) / size);
  float xPixel = mod(float(j), size); 
  
  // Exact center-pixel sampling positions matching texelFetch precision
  vec2 uv1 = vec2(xPixel + 0.5, yPixel + 0.5) / size;
  vec2 uv2 = vec2(xPixel + 1.5, yPixel + 0.5) / size;
  vec2 uv3 = vec2(xPixel + 2.5, yPixel + 0.5) / size;
  vec2 uv4 = vec2(xPixel + 3.5, yPixel + 0.5) / size;
  
  vec4 v1 = texture(unifiedTransformationTexture, uv1); 
  vec4 v2 = texture(unifiedTransformationTexture, uv2); 
  vec4 v3 = texture(unifiedTransformationTexture, uv3); 
  vec4 v4 = texture(unifiedTransformationTexture, uv4);
  
  return mat4(v1, v2, v3, v4);
}

mat4 getSkinMatrix(vec4 skinIndex, vec4 skinWeight) {
  mat4 bindMatrix = material.bindMatrices[0];
  mat4 bindMatrixInverse = material.bindMatrices[1];
  
  mat4 boneMatX = getBoneMatrix(skinIndex.x);
  mat4 boneMatY = getBoneMatrix(skinIndex.y);
  mat4 boneMatZ = getBoneMatrix(skinIndex.z);
  mat4 boneMatW = getBoneMatrix(skinIndex.w);
  
  mat4 skinMatrix = 
      boneMatX * skinWeight.x +
      boneMatY * skinWeight.y +
      boneMatZ * skinWeight.z +
      boneMatW * skinWeight.w;
      
  return bindMatrixInverse * skinMatrix * bindMatrix;
}

vec4 getSkinPosition(vec4 skinIndex, vec4 skinWeight, vec3 position) {
  return getSkinMatrix(skinIndex,skinWeight) * vec4(position,1.0);
}

vec3 getMorphTargetOffset(float vertexId) {
    float morphTargetsCount = material.boneTextureParm.x;  // Now cleanly resolves to texWidth
    float totalVerticesCount = material.boneTextureParm.y; // Now cleanly resolves to texHeight
    
    if (morphTargetsCount <= 0.0 || totalVerticesCount <= 0.0) return vec3(0.0);

    // Force instance vertexIDs to wrap perfectly into your base template range bounds
    float localRowIndex = mod(floor(vertexId + 0.01), totalVerticesCount);
    
    float v = clamp((localRowIndex + 0.5) / totalVerticesCount, 0.0, 1.0);

    vec3 blendedOffset = vec3(0.0);

    float w0 = material.materialParams.x;
    float w1 = material.materialParams.y;
    float w2 = material.materialParams.z;
    float w3 = material.materialParams.w;

    if (w0 > 0.01) blendedOffset += texture(unifiedTransformationTexture, vec2(0.5 / morphTargetsCount, v)).rgb * w0;
    if (w1 > 0.01) blendedOffset += texture(unifiedTransformationTexture, vec2(1.5 / morphTargetsCount, v)).rgb * w1;
    if (w2 > 0.01) blendedOffset += texture(unifiedTransformationTexture, vec2(2.5 / morphTargetsCount, v)).rgb * w2;
    if (w3 > 0.01) blendedOffset += texture(unifiedTransformationTexture, vec2(3.5 / morphTargetsCount, v)).rgb * w3;

    return blendedOffset;
}
