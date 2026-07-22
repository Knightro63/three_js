layout(binding = 3) uniform sampler2D instanceTexture;

mat4 getInstanceMatrix(float instanceID) {
  float computedInstanceId = floor(instanceID + 0.01);
  float texWidth = 4.0;
  
  float baseCount = material.instanceTextureParm.w; 
  float texHeight = material.instanceTextureParm.z;
  float maxValue = 1.0; 

  if (baseCount != texHeight) {
      maxValue = baseCount / texHeight;
  }
  
  if (texHeight <= 0.0) texHeight = 1.0;

  float v = clamp((computedInstanceId + 0.5) / texHeight, 0.0, maxValue);

  vec4 row1 = texture(instanceTexture, vec2(0.5 / texWidth, v));
  vec4 row2 = texture(instanceTexture, vec2(1.5 / texWidth, v));
  vec4 row3 = texture(instanceTexture, vec2(2.5 / texWidth, v));
  vec4 row4 = texture(instanceTexture, vec2(3.5 / texWidth, v));
  
  return mat4(row1, row2, row3, row4);
}

vec3 getInstanceColor(vec3 color, float instanceID) {
  bool hasInstancingColor = material.flags5.w > 2.5;
  if(!hasInstancingColor){
    if (dot(color, color) <= 0.0) {
      vec3(1.0);
    }
    return color;
  }
  float id = floor(instanceID + 0.01);
  float texWidth = 4.0;
  
  float baseCount = material.instanceTextureParm.w; // uniformData (e.g., 1000.0)
  float texHeight = material.instanceTextureParm.z; // uniformData (e.g., 1250.0)

  if (texHeight <= 0.0) texHeight = 1.0;

  // Use your 4-instances-per-row color math layout
  float colorRowOffset = floor(id / 4.0);
  float colorPixelOffset = mod(id, 4.0);

  // Shift targetRow downward past the complete matrix block height
  float targetRow = baseCount + colorRowOffset;
  
  float v = clamp((targetRow + 0.5) / texHeight, 0.0, 1.0);
  float u = (colorPixelOffset + 0.5) / texWidth;

  return texture(instanceTexture, vec2(u, v)).rgb;
}

mat4 getBatchingMatrix(float instanceID) {
  float texWidth = material.instanceTextureParm.x;
  float texHeight = material.instanceTextureParm.y;
  float pixelIndex = instanceID * 4.0;
  
  float pixelX = fract(pixelIndex / texWidth) * texWidth;
  float pixelY = floor(pixelIndex / texWidth);
  
  vec2 uv1 = vec2(pixelX + 0.5, pixelY + 0.5) / texHeight;
  vec2 uv2 = vec2(pixelX + 1.5, pixelY + 0.5) / texHeight;
  vec2 uv3 = vec2(pixelX + 2.5, pixelY + 0.5) / texHeight;
  vec2 uv4 = vec2(pixelX + 3.5, pixelY + 0.5) / texHeight;

  vec4 v1 = texture(instanceTexture, uv1);
  vec4 v2 = texture(instanceTexture, uv2);
  vec4 v3 = texture(instanceTexture, uv3);
  vec4 v4 = texture(instanceTexture, uv4);
  
  return mat4(v1, v2, v3, v4);
}

mat4 getBatchingInstance(float instanceID) {
  if(material.flags5.w  < 0.5){
    return mat4(1.0);
  }
  else if(material.flags5.w  < 1.5){
    return getBatchingMatrix(instanceID);
  }
  else{
    return getInstanceMatrix(instanceID);
  }
}