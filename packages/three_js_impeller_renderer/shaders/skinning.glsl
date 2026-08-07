layout(binding = 2) uniform sampler2D boneTexture;

struct BoneMatrix {
  mat4 boneMatX;
  mat4 boneMatY;
  mat4 boneMatZ;
  mat4 boneMatW;
};

mat4 getBoneMatFromText(float i) {
  float size = material.boneTextureParm.x;
  if (size <= 0.0) size = 4.0;

  int j = int(floor(i + 0.5)) * 4;
  int sizeInt = int(size);

  int pixelY = j / sizeInt;
  int pixelX = int(j - sizeInt * floor(pixelY));//j % sizeInt;
  

  int targetY = pixelY;

  vec2 uv1 = vec2(float(pixelX) + 0.5, float(targetY) + 0.5) / size;
  vec2 uv2 = vec2(float(pixelX) + 1.5, float(targetY) + 0.5) / size;
  vec2 uv3 = vec2(float(pixelX) + 2.5, float(targetY) + 0.5) / size;
  vec2 uv4 = vec2(float(pixelX) + 3.5, float(targetY) + 0.5) / size;

  vec4 v1 = texture(boneTexture, uv1);
  vec4 v2 = texture(boneTexture, uv2);
  vec4 v3 = texture(boneTexture, uv3);
  vec4 v4 = texture(boneTexture, uv4);

  return mat4(v1, v2, v3, v4);
}

BoneMatrix getBoneMatrix(vec4 skinIndex, vec4 skinWeight){
  if (material.flags0.x < 0.5 || material.flags0.x > 1.5) {
    return BoneMatrix(mat4(1.0),mat4(1.0),mat4(1.0),mat4(1.0));
  }
  mat4 boneMatX = getBoneMatFromText(skinIndex.x);
  mat4 boneMatY = getBoneMatFromText(skinIndex.y);
  mat4 boneMatZ = getBoneMatFromText(skinIndex.z);
  mat4 boneMatW = getBoneMatFromText(skinIndex.w);

  return BoneMatrix(boneMatX,boneMatY,boneMatZ,boneMatW);
}

vec4 getSkinPosition(BoneMatrix boneMatrix, vec4 skinWeight, vec4 position) {
  if (material.flags0.x < 0.5 || material.flags0.x > 1.5) {
    return position;
  }

  if (dot(skinWeight, vec4(1.0)) < 0.001) {
    return position;
  }

  mat4 bindMatrix = material.bindMatrices[0];
  mat4 bindMatrixInverse = material.bindMatrices[1];

  vec4 skinVertex = bindMatrix * position;
  vec4 skinned = vec4(0.0);
  
  skinned += boneMatrix.boneMatX * skinVertex * skinWeight.x;
  skinned += boneMatrix.boneMatY * skinVertex * skinWeight.y;
  skinned += boneMatrix.boneMatZ * skinVertex * skinWeight.z;
  skinned += boneMatrix.boneMatW * skinVertex * skinWeight.w;
  
  return bindMatrixInverse * skinned;
}

vec3 getSkinNormal(BoneMatrix boneMatrix, vec4 skinWeight, vec3 normal) {
  if (material.flags0.x < 0.5 || material.flags0.x > 1.5) { 
    return normal; 
  } 
  
  mat4 skinMatrix = mat4(0.0); 
  
  skinMatrix += boneMatrix.boneMatX * skinWeight.x; 
  skinMatrix += boneMatrix.boneMatY * skinWeight.y; 
  skinMatrix += boneMatrix.boneMatZ * skinWeight.z; 
  skinMatrix += boneMatrix.boneMatW * skinWeight.w; 
  skinMatrix = material.bindMatrices[1] * skinMatrix * material.bindMatrices[0]; 
  
  return normalize((skinMatrix * vec4(normal, 0.0)).xyz); 
}