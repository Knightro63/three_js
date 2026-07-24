layout(binding = 3) uniform sampler2D morphTexture;       // Contains the weights per instance
layout(binding = 4) uniform sampler2D morphTargetTexture; // Contains raw vertex offset vectors
layout(binding = 5) uniform MorphParams morphParams;

struct MorphParams {
  float useMorphTargets;       // 1.0 = Enable morphing, 0.0 = Skip morphing
  vec2 morphTextureParm;       // x = Width/Size of the weights texture
  vec2 morphTargetTextureParm; // x = Width/Size of the displacement texture
};

const int MORPHTARGETS_COUNT = 8; 

struct MorphData {
  float baseInfluence;
  float influences[MORPHTARGETS_COUNT];
};

MorphData getMorphInfluences() {
  MorphData data;
  
  float size = morphParams.morphTextureParm.x; 
  if (size <= 0.0) { size = 4.0; }
  
  int targetY = gl_InstanceID; 
  
  int pixelX_Base = 0;
  vec2 uvBase = vec2(float(pixelX_Base) + 0.5, float(targetY) + 0.5) / size;
  data.baseInfluence = texture(morphTexture, uvBase).r;
  
  for (int i = 0; i < MORPHTARGETS_COUNT; i++) {
    int pixelX_Index = i + 1;
    vec2 uvInfluence = vec2(float(pixelX_Index) + 0.5, float(targetY) + 0.5) / size;
    data.influences[i] = texture(morphTexture, uvInfluence).r;
  }
  
  return data;
}

vec3 getMorphPositionOffset(int vertexID, int targetIndex) {
  float size = morphParams.morphTargetTextureParm.x;
  if (size <= 0.0) { size = 2048.0; }
  int sizeInt = int(size);
  
  // Three.js Stride configuration: 3 vectors per morph target (Position=0, Normal=1, Tangent=2)
  int vertexStride = MORPHTARGETS_COUNT * 3;
  
  // Calculate the flat texel index for the POSITION data of this vertex/target combo
  int flatTexelIndex = (vertexID * vertexStride) + (targetIndex * 3 + 0);
  
  // Apply your exact row-major wrapping math
  int pixelX = flatTexelIndex % sizeInt;
  int pixelY = flatTexelIndex / sizeInt;
  
  vec2 uv = vec2(float(pixelX) + 0.5, float(pixelY) + 0.5) / size;
  
  return texture(morphTargetTexture, uv).xyz;
}

vec4 getMorphedPosition(vec4 position) {
  if (morphParams.useMorphTargets < 0.5) {
    return position;
  }
  
  vec3 transformed = position.xyz;
  MorphData morph = getMorphInfluences();
  
  transformed *= morph.baseInfluence;
  
  for (int i = 0; i < MORPHTARGETS_COUNT; i++) {
    if (morph.influences[i] != 0.0) {
      vec3 morphOffset = getMorphPositionOffset(gl_VertexID, i);
      transformed += morphOffset * morph.influences[i];
    }
  }
  
  return vec4(transformed, position.w);
}

vec3 getMorphNormalOffset(int vertexID, int targetIndex) {
  float size = morphParams.morphTargetTextureParm.x;
  if (size <= 0.0) { size = 2048.0; }
  int sizeInt = int(size);
  
  int vertexStride = MORPHTARGETS_COUNT * 3;
  
  int flatTexelIndex = (vertexID * vertexStride) + (targetIndex * 3 + 1);
  
  int pixelX = flatTexelIndex % sizeInt;
  int pixelY = flatTexelIndex / sizeInt;
  
  vec2 uv = vec2(float(pixelX) + 0.5, float(pixelY) + 0.5) / size;
  
  return texture(morphTargetTexture, uv).xyz;
}

vec3 getMorphedNormal(vec3 objectNormal, MorphData morph) {
  if (morphParams.useMorphTargets < 0.5) {
    return objectNormal;
  }
  
  vec3 transformedNormal = objectNormal;
  
  transformedNormal *= morph.baseInfluence;
  
  for (int i = 0; i < MORPHTARGETS_COUNT; i++) {
    if (morph.influences[i] != 0.0) {
      vec3 normalOffset = getMorphNormalOffset(gl_VertexID, i);
      transformedNormal += normalOffset * morph.influences[i];
    }
  }
  
  return transformedNormal;
}

