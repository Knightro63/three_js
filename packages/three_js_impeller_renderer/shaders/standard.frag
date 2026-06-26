#include <common.glsl> 
#include <light.glsl> 
#include <fog.glsl> 
#include <color.glsl> 
#include <clipping.glsl> 
#include <flat_shading.glsl> 

uniform sampler2D map; 
uniform sampler2D alphaMap; 
uniform sampler2D normalMap; 
uniform sampler2D bumpMap; 
uniform sampler2D ormMap; 
uniform sampler2D lightMap; 
uniform sampler2D emissiveMap; 

in vec3 v_color; 
in vec3 v_worldPosition; 
in vec3 v_worldNormal; 
in vec2 v_uv; 

in vec4 v_skinIndex;
in vec4 v_skinWeight;

out vec4 frag_color; 

// Arbitrary surface normal perturbation calculation block 
vec3 perturbNormalArb(vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection) { 
  vec3 vSigmaX = dFdx(surf_pos); 
  vec3 vSigmaY = dFdy(surf_pos); 
  vec3 vN = surf_norm; 
  vec3 R1 = cross(vSigmaY, vN); 
  vec3 R2 = cross(vN, vSigmaX); 
  float fDet = dot(vSigmaX, R1); 
  fDet *= faceDirection; 
  vec3 vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2); 
  return normalize(abs(fDet) * vN - vGrad); 
} 

void main() { 
  if(evaluateClippingPlanes(v_worldPosition)){
    discard;
  }  

  // Resolve precise uniform configuration maps boolean flag states from MaterialBlock 
  bool hasMap          = material.flags0.y > 0.5; // Index 93 
  bool hasAlphaMap     = material.flags0.z > 0.5; // Index 94 
  bool hasAoMap        = material.flags0.w > 0.5; // Index 95 
  bool hasNormalMap    = material.flags1.w > 0.5; // Index 99 
  bool hasBumpMap      = material.flags1.z > 0.5; // Index 98 
  bool hasRoughnessMap = material.flags2.y > 0.5; // Index 101 
  bool hasMetalnessMap = material.flags2.z > 0.5; // Index 102 
  bool hasEmissiveMap  = material.flags2.w > 0.5; // Index 103 
  bool hasLightMap     = material.flags1.y > 0.5; // Index 97 

  // 1. Process Albedo Base color 
  vec4 texelColor = vec4(1.0); 
  float alphaOverride = material.baseColor.a; 

  if (hasMap) { 
    texelColor = texture(map, v_uv); 
    alphaOverride = material.baseColor.a * texelColor.a; 
  } 
  vec3 blendedAlbedo = v_color * texelColor.rgb; 

  // 2. Process Transparency Alpha testing early workaround layout 
  float alpha = alphaOverride; 
  if (hasAlphaMap) { 
    alpha *= texture(alphaMap, v_uv).g; 
  } 

  if (alpha < material.pbrParams.w) { // material.pbrParams.w = alphaTest 
    frag_color = vec4(0.0); 
    return; 
  } 

  // 3. Process Material Grayscale Ambient Occlusion 
  if (hasAoMap) { 
    blendedAlbedo *= texture(ormMap, v_uv).r * material.mapIntensities.w; // material.aoMapIntensity 
  } 

  // 4. Process Baked Environment Light Maps 
  if (hasLightMap) { 
    blendedAlbedo += texture(lightMap, v_uv).rgb * material.mapIntensities.z; // material.lightMapIntensity 
  } 

  // 5. Convert Albedo Color space into working linear physics room 
  vec3 linearAlbedo = sRGBTransferEETF(vec4(blendedAlbedo, 1.0)).rgb; 

  // 6. Gather and Parse PBR Specific parameters properties 
  float roughnessFactor = material.pbrParams.x; // default raw uniform roughness 
  if (hasRoughnessMap) { 
    roughnessFactor *= texture(ormMap, v_uv).g; // Three.js reads green for roughness 
  } 

  float metalnessFactor = material.pbrParams.y; // default raw uniform metalness 
  if (hasMetalnessMap) { 
    metalnessFactor *= texture(ormMap, v_uv).b; // Three.js reads blue for metalness 
  } 

  // 7. Surface Normal Evaluation (Smooth vs Facetted) 
  vec3 N = evaluateNormal(v_worldNormal, v_worldPosition); 

  if (hasNormalMap) { 
    vec3 normalMapSample = texture(normalMap, v_uv).xyz * 2.0 - 1.0; 
    // THE COORD FIX: Normal scale mapping is tracked inside material.mapIntensities.x (bumpScale)
    normalMapSample.xy *= material.mapIntensities.x; 
    vec2 dHdxy = normalMapSample.xy; 
    float faceDirection = gl_FrontFacing ? 1.0 : -1.0; 
    N = perturbNormalArb(v_worldPosition, N, dHdxy, faceDirection); 
  } 
  else if (hasBumpMap) { 
    float bumpSample = texture(bumpMap, v_uv).r; 
    vec2 dHdxy = vec2(dFdx(bumpSample), dFdy(bumpSample)) * material.mapIntensities.x; // material.bumpScale 
    float faceDirection = gl_FrontFacing ? 1.0 : -1.0; 
    N = perturbNormalArb(v_worldPosition, N, dHdxy, faceDirection); 
  } 

  // Camera perspective direction vector calculations 
  vec3 V = normalize(scene.cameraPosition.xyz - v_worldPosition); 

  // 8. Execute Dynamic Lights calculation loop 
  vec3 specularColorReflection = vec3(metalnessFactor); 
  vec3 finalColor = calculateDynamicLighting(N, V, v_worldPosition, linearAlbedo, roughnessFactor, specularColorReflection); 

  if (hasEmissiveMap) { 
    vec3 emissiveSample = texture(emissiveMap, v_uv).rgb; 
    finalColor += material.emissiveColor.rgb * emissiveSample; 
  } 

  // 10. Post-Lighting Environment Layers Integration 
  finalColor = applyFog(finalColor, v_worldPosition); 
  vec4 finalRGBA = vec4(finalColor, alpha); 

  // Isolate color grading space conversions to protect transparency channel lines 
  finalRGBA= applyColor(finalRGBA,material.lineExtendedParams.z); 
  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a); 
}
