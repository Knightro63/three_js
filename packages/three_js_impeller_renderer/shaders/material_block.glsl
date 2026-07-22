layout(std140, binding = 0) uniform MaterialBlock {
  mat4 modelMatrix;
  mat4 projectionMatrix; // scene.projectionMatrix
  mat4 viewMatrix; //scene.viewMatrix
  mat4 bindMatrices[2];
  
  vec4 cameraPosition;    // w = isOrthographic
  vec4 baseColor;
  vec4 emissiveColor;
  
  vec4 pbrParams;
  vec4 materialParams;
  vec4 mapIntensities;
  vec4 specularAndIOR;
  vec4 sheenColorAndIntensity;
  vec4 physicalAdvancedParams;
  vec4 attenuationParms;
  vec4 lineParams;
  vec4 lineExtendedParams;
  vec4 displacementParams; //displacment scale, bias, blending, padding
  
  vec4 clippingPlanes[6];
  vec4 cpp;  // numOfPlanes, unionClippingPlanes, useAlphaToCoverage, padding

  vec4 boneTextureParm; //bone/morph
  vec4 instanceTextureParm; //instance/batching

  // Parallel primitive vectors matching your Float32List indices exactly!
  vec4 flags0; // x:hasBoneTexture,          y:hasMap,               z:hasAlphaMap,          w:hasAoMap
  vec4 flags1; // x:hasSpecularMap,     y:hasLightMap,          z:hasBumpMap,           w:hasNormalMap
  vec4 flags2; // x:hasDisplacementMap, y:hasRoughnessMap,      z:hasMetalnessMap,      w:hasEmissiveMap
  vec4 flags3; // x:hasClearcoatMap,    y:hasClearcoatNormalMap,z:hasClearcoatRoughMap, w:hasSheenColorMap
  vec4 flags4; // x:hasSheenRoughMap,   y:hasTransmissionMap,   z:hasThicknessMap,      w:hasIridescenceMap
  vec4 flags5; // x:hasIridescenceThick,y:hasGradientMap,       z:hasMatcap,            w:hasInstance
} material;