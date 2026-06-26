layout(std140, binding = 0) uniform SceneBlock {
  // Nested scene parameters
  mat4 projectionMatrix;
  mat4 viewMatrix;
  vec4 cameraPosition;    // w = lightCount
  vec4 ambientColor;
  vec4 fogColor;
  vec4 fogParams;         // near, far, density, isFogExp2
  
  // Parallel primitive arrays replacing the Light struct array
  vec4 lightPositions[16];
  vec4 lightColors[16];
  vec4 lightAttenuationParams[16];
  vec4 lightExtendedParams[16];
} scene;

layout(std140, binding = 1) uniform MaterialBlock {
  // Core mesh properties
  mat4 modelMatrix;        // 0-15
  vec4 baseColor;          // 16-19
  vec4 emissiveColor;      // 20-23
  vec4 pbrParams;          // 24-27
  vec4 materialParams;     // 28-31
  vec4 mapIntensities;     // 32-35
  vec4 specularAndIOR;     // 36-39
  vec4 sheenColorAndIntensity; // 40-43
  vec4 physicalAdvancedParams; //44-47
  vec4 attenuationColorVec; // 48-51
  vec4 lineParams;         // 52-55
  vec4 lineExtendedParams; // 56-59
  vec4 morphInfluences0;   // 60-63
  vec4 morphInfluences1;   // 64-67
  
  vec4 clippingPlanes[6];  //68-91
  vec4 cpp;  // numOfPlanes, unionClippingPlanes, useAlphaToCoverage, padding

  // Parallel primitive vectors matching your Float32List indices exactly!
  vec4 flags0; // 92-95 x:hasBoneTexture,          y:hasMap,               z:hasAlphaMap,          w:hasAoMap
  vec4 flags1; // 96-99 x:hasSpecularMap,     y:hasLightMap,          z:hasBumpMap,           w:hasNormalMap
  vec4 flags2; // 100-103 x:hasDisplacementMap, y:hasRoughnessMap,      z:hasMetalnessMap,      w:hasEmissiveMap
  vec4 flags3; // 104-107 x:hasClearcoatMap,    y:hasClearcoatNormalMap,z:hasClearcoatRoughMap, w:hasSheenColorMap
  vec4 flags4; // 108-109 x:hasSheenRoughMap,   y:hasTransmissionMap,   z:hasThicknessMap,      w:hasIridescenceMap
  vec4 flags5; // 112-115 x:hasIridescenceThick,y:hasGradientMap,       z:hasMatcap,            w:padding

  mat4 bindMatrices[2]; //matrix, inverse
  vec4 boneTextureParm;
} material;