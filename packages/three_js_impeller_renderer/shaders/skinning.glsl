layout(binding = 2) uniform sampler2D unifiedTransformationTexture;

// struct MorphInfluenceResult {
//   float baseInfluence;
//   float targets[MORPHTARGETS_COUNT];
// };

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

  int pixelX = j % sizeInt;
  int pixelY = j / sizeInt;

  int targetY = pixelY;

  vec2 uv1 = vec2(float(pixelX) + 0.5, float(targetY) + 0.5) / size;
  vec2 uv2 = vec2(float(pixelX) + 1.5, float(targetY) + 0.5) / size;
  vec2 uv3 = vec2(float(pixelX) + 2.5, float(targetY) + 0.5) / size;
  vec2 uv4 = vec2(float(pixelX) + 3.5, float(targetY) + 0.5) / size;

  vec4 v1 = texture(unifiedTransformationTexture, uv1);
  vec4 v2 = texture(unifiedTransformationTexture, uv2);
  vec4 v3 = texture(unifiedTransformationTexture, uv3);
  vec4 v4 = texture(unifiedTransformationTexture, uv4);

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

// MorphInfluenceResult getInstancedMorphInfluences(int instanceID) {
//   MorphInfluenceResult result;
//   float morphTargetsCount = material.boneTextureParm.w;  // Now cleanly resolves to texWidth
  
//   float texWidth = material.boneTextureParm.x;
//   float texHeight = material.boneTextureParm.y;
//   vec2 morphTextureSize = vec2(texWidth,texHeight)
  
//   // Safety check to prevent division by zero or empty reads
//   if (texWidth <= 0.0 || texHeight <= 0.0) {
//     result.baseInfluence = 1.0;
//     for (int i = 0; i < morphTargetsCount; i++) result.targets[i] = 0.0;
//     return result;
//   }

//   // Y coordinate represents the specific instance index lane
//   float yPixel = float(instanceID);

//   // 1. Fetch the Morph Base Influence (Stored at Column X = 0)
//   vec2 baseUV = vec2(0.0 + 0.5, yPixel + 0.5) / morphTextureSize;
//   result.baseInfluence = texture(unifiedTransformationTexture, baseUV).r;

//   // 2. Fetch the individual morph targets sequentially (Columns X = i + 1)
//   for (int i = 0; i < morphTargetsCount; i++) {
//     float xPixel = float(i + 1);
//     vec2 targetUV = vec2(xPixel + 0.5, yPixel + 0.5) / morphTextureSize;
    
//     result.targets[i] = texture(unifiedTransformationTexture, targetUV).r;
//   }

//   return result;
// }

// vec3 getMorphTargetOffset(float vertexId) {
//   float morphTargetsCount = material.boneTextureParm.x;  // Now cleanly resolves to texWidth
//   float totalVerticesCount = material.boneTextureParm.y; // Now cleanly resolves to texHeight
  
//   if (morphTargetsCount <= 0.0 || totalVerticesCount <= 0.0) return vec3(0.0);

//   // Force instance vertexIDs to wrap perfectly into your base template range bounds
//   float localRowIndex = mod(floor(vertexId + 0.01), totalVerticesCount);
  
//   float v = clamp((localRowIndex + 0.5) / totalVerticesCount, 0.0, 1.0);

//   vec3 blendedOffset = vec3(0.0);

//   float w0 = material.materialParams.x;
//   float w1 = material.materialParams.y;
//   float w2 = material.materialParams.z;
//   float w3 = material.materialParams.w;

//   if (w0 > 0.01) blendedOffset += texture(unifiedTransformationTexture, vec2(0.5 / morphTargetsCount, v)).rgb * w0;
//   if (w1 > 0.01) blendedOffset += texture(unifiedTransformationTexture, vec2(1.5 / morphTargetsCount, v)).rgb * w1;
//   if (w2 > 0.01) blendedOffset += texture(unifiedTransformationTexture, vec2(2.5 / morphTargetsCount, v)).rgb * w2;
//   if (w3 > 0.01) blendedOffset += texture(unifiedTransformationTexture, vec2(3.5 / morphTargetsCount, v)).rgb * w3;

//   return blendedOffset;
// }
