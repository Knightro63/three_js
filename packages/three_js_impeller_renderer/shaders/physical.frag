#include <common.glsl>
#include <light.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <flat_shading.glsl>

// Core Mesh Samplers
uniform sampler2D map;
uniform sampler2D alphaMap;
uniform sampler2D normalMap;
uniform sampler2D bumpMap;
uniform sampler2D lightMap;
uniform sampler2D emissiveMap;

// Channel-Packed PBR Map (Red = AO, Green = Roughness, Blue = Metalness)
uniform sampler2D ormMap;

// Channel-Packed Clearcoat Properties (Red = Intensity, Green = Roughness)
uniform sampler2D clearcoatParamsMap;
uniform sampler2D clearcoatNormalMap;

// Channel-Packed Advanced Extensions (Red = Transmission, Green = Thickness, Blue = Iridescence)
uniform sampler2D advancedPhysicalMap;
uniform sampler2D iridescenceThicknessMap;
uniform sampler2D sheenColorMap;
uniform sampler2D sheenRoughnessMap;

in vec3 v_color;
in vec3 v_worldPosition;
in vec3 v_worldNormal;
in vec2 v_uv;

out vec4 frag_color;

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

vec3 schlickFresnel(vec3 f0, float dotNV) {
  return f0 + (vec3(1.0) - f0) * pow(clamp(1.0 - dotNV, 0.0, 1.0), 5.0);
}

void main() {
  // 1. Evaluate clipping slices and discard clipped pixel fragments completely
  if (evaluateClippingPlanes(v_worldPosition)) {
    discard;
  }

  // 2. Resolve Material Configuration Bitmask Flags from layout arrays
  bool hasMap           = material.flags0.y > 0.5; // Index 93
  bool hasAlphaMap      = material.flags0.z > 0.5; // Index 94
  bool hasAoMap         = material.flags0.w > 0.5; // Index 95
  bool hasLightMap      = material.flags1.y > 0.5; // Index 97
  bool hasBumpMap       = material.flags1.z > 0.5; // Index 98
  bool hasNormalMap     = material.flags1.w > 0.5; // Index 99
  bool hasRoughnessMap  = material.flags2.y > 0.5; // Index 101
  bool hasMetalnessMap  = material.flags2.z > 0.5; // Index 102
  bool hasEmissiveMap   = material.flags2.w > 0.5; // Index 103

  // MeshPhysicalMaterial Packed Channel Flags
  bool hasClearcoatMap       = material.flags3.x > 0.5; // Index 104
  bool hasClearcoatNormalMap = material.flags3.y > 0.5; // Index 105
  bool hasClearcoatRoughMap  = material.flags3.z > 0.5; // Index 106
  bool hasSheenColorMap      = material.flags3.w > 0.5; // Index 107
  bool hasSheenRoughMap      = material.flags4.x > 0.5; // Index 108
  bool hasTransmissionMap    = material.flags4.y > 0.5; // Index 109
  bool hasThicknessMap       = material.flags4.z > 0.5; // Index 110
  bool hasIridescenceMap     = material.flags4.w > 0.5; // Index 111
  bool hasIridescenceThick   = material.flags5.x > 0.5; // Index 112

  // 3. Process Base Albedo and Opacity Channels
  vec4 texelColor = vec4(1.0);
  float alphaOverride = material.baseColor.a;
  if (hasMap) {
    texelColor = texture(map, v_uv);
    alphaOverride = material.baseColor.a * texelColor.a;
  }
  vec3 blendedAlbedo = v_color * texelColor.rgb;

  float alpha = alphaOverride;
  if (hasAlphaMap) {
    alpha *= texture(alphaMap, v_uv).g;
  }
  if (alpha < material.pbrParams.w) { // material.pbrParams.w = alphaTest
    discard;
  }

  // 4. Sample the Channel-Packed PBR 'ORM' texture map
  vec4 ormSample = vec4(1.0);
  if (hasAoMap || hasRoughnessMap || hasMetalnessMap) {
    ormSample = texture(ormMap, v_uv);
  }

  if (hasAoMap) {
    blendedAlbedo *= ormSample.r * material.mapIntensities.w; // ormSample.r = AO
  }
  if (hasLightMap) {
    blendedAlbedo += texture(lightMap, v_uv).rgb * material.mapIntensities.z;
  }

  // Convert color space into linear math workspace
  vec3 linearAlbedo = sRGBTransferEETF(vec4(blendedAlbedo, 1.0)).rgb;
  // 5. Parse Base PBR parameters from uniform variables and packed ORM maps
  float roughnessFactor = material.pbrParams.x;
  if (hasRoughnessMap) {
    roughnessFactor *= ormSample.g; // ormSample.g = Roughness
  }
  float metalnessFactor = material.pbrParams.y;
  if (hasMetalnessMap) {
    metalnessFactor *= ormSample.b; // ormSample.b = Metalness
  }

  // --- PACKED PHYSICAL EXTENSION COEFFICIENTS ---
  // Sample Channel-Packed Clearcoat Parameters
  vec4 ccSample = vec4(1.0);
  if (hasClearcoatMap || hasClearcoatRoughMap) {
    ccSample = texture(clearcoatParamsMap, v_uv);
  }
  
  float clearcoatFactor = material.physicalAdvancedParams.x;
  if (hasClearcoatMap) {
    clearcoatFactor *= ccSample.r; // ccSample.r = Clearcoat Intensity
  }

  float clearcoatRoughness = material.physicalAdvancedParams.y;
  if (hasClearcoatRoughMap) {
    clearcoatRoughness *= ccSample.g; // ccSample.g = Clearcoat Roughness
  }
  clearcoatRoughness = clamp(clearcoatRoughness, 0.04, 1.0);

  // Sheen
  vec3 sheenColorFactor = material.sheenColorAndIntensity.rgb;
  if (hasSheenColorMap) {
    sheenColorFactor *= texture(sheenColorMap, v_uv).rgb;
  }
  float sheenRoughnessFactor = material.sheenColorAndIntensity.w;
  if (hasSheenRoughMap) {
    sheenRoughnessFactor *= texture(sheenRoughnessMap, v_uv).g;
  }

  // Sample Channel-Packed Transmission, Thickness, and Iridescence
  vec4 advSample = vec4(1.0);
  if (hasTransmissionMap || hasThicknessMap || hasIridescenceMap) {
    advSample = texture(advancedPhysicalMap, v_uv);
  }

  float transmissionFactor = material.physicalAdvancedParams.z;
  if (hasTransmissionMap) {
    transmissionFactor *= advSample.r; // advSample.r = Transmission Intensity
  }
  float thicknessFactor = material.physicalAdvancedParams.w;
  if (hasThicknessMap) {
    thicknessFactor *= advSample.g; // advSample.g = Volumetric Thickness
  }

  // Iridescence
  float iridescenceFactor = material.attenuationColorVec.w;
  if (hasIridescenceMap) {
    iridescenceFactor *= advSample.b; // advSample.b = Iridescence Intensity
  }
  float iridescenceIOR = material.lineParams.x;
  float iridescenceThickness = material.lineParams.y;
  if (hasIridescenceThick) {
    iridescenceThickness *= texture(iridescenceThicknessMap, v_uv).g;
  }

  // --- SURFACE NORMAL EVALUATION ---
  float faceDirection = gl_FrontFacing ? 1.0 : -1.0;
  vec3 baseNormal = evaluateNormal(v_worldNormal, v_worldPosition);
  vec3 N = baseNormal;

  if (hasNormalMap) {
    vec3 normalMapSample = texture(normalMap, v_uv).xyz * 2.0 - 1.0;
    normalMapSample.xy *= material.mapIntensities.x;
    N = perturbNormalArb(v_worldPosition, N, normalMapSample.xy, faceDirection);
  } 
  else if (hasBumpMap) {
    float bumpSample = texture(bumpMap, v_uv).r;
    vec2 dHdxy = vec2(dFdx(bumpSample), dFdy(bumpSample)) * material.mapIntensities.x;
    N = perturbNormalArb(v_worldPosition, N, dHdxy, faceDirection);
  }

  // --- RE-PERTURB INDEPENDENT CLEARCOAT NORMAL ---
  vec3 clearcoatN = baseNormal;
  if (hasClearcoatNormalMap) {
    vec3 ccNormalSample = texture(clearcoatNormalMap, v_uv).xyz * 2.0 - 1.0;
    ccNormalSample.xy *= material.lineParams.z;
    clearcoatN = perturbNormalArb(v_worldPosition, clearcoatN, ccNormalSample.xy, faceDirection);
  }
  // --- FRAGMENT VECTOR RE-NORMALIZATION (Kills White Specular Bleeding) ---
  vec3 N_clean = normalize(N);
  vec3 V_clean = normalize(scene.cameraPosition.xyz - v_worldPosition);
  vec3 clearcoatN_clean = normalize(clearcoatN);

  float dotNV = clamp(dot(N_clean, V_clean), 0.0, 1.0);
  float dotClearcoatNV = clamp(dot(clearcoatN_clean, V_clean), 0.0, 1.0);

  // --- EVALUATE FRESNEL AND SPECULAR (IOR Integration) ---
  float ior = material.specularAndIOR.w; 
  vec3 f0 = vec3(pow((ior - 1.0) / (ior + 1.0), 2.0));
  
  vec3 specularColorReflection = mix(f0 * material.specularAndIOR.rgb, linearAlbedo, metalnessFactor);

  // --- IRIDESCENCE FRESNEL SHIFT MODIFICATION ---
  if (iridescenceFactor > 0.05) {
    float eta2 = pow(iridescenceIOR, 2.0);
    float sinTheta2 = 1.0 - pow(dotNV, 2.0);
    float cosThetaT = sqrt(max(0.0, eta2 - sinTheta2));
    
    vec3 iridescenceFresnel = vec3(0.5) + 0.5 * cos(vec3(6.28318) * (iridescenceThickness * cosThetaT / 500.0));
    specularColorReflection = mix(specularColorReflection, iridescenceFresnel, iridescenceFactor);
  }

  // --- BASE PBR LIGHTING EXECUTION ---
  vec3 baseLighting = calculateDynamicLighting(N_clean, V_clean, v_worldPosition, linearAlbedo, roughnessFactor, specularColorReflection);

  // --- INTEGRATE SHEEN LAYER ---
  if (max(sheenColorFactor.r, max(sheenColorFactor.g, sheenColorFactor.b)) > 0.0) {
    float sheenFresnel = pow(1.0 - dotNV, 4.0);
    vec3 sheenLayer = sheenColorFactor * sheenFresnel * (1.0 - sheenRoughnessFactor);
    baseLighting += sheenLayer;
  }

  // --- INTEGRATE TRANSMISSION LAYER ---
  if (transmissionFactor > 0.0) {
    vec3 transmissionColor = material.attenuationColorVec.rgb; 
    float attenuationDistance = material.lineParams.w;        
    
    vec3 thicknessAttenuation = vec3(1.0);
    if (attenuationDistance > 0.0) {
      vec3 absorption = -log(max(transmissionColor, vec3(0.0001))) / attenuationDistance;
      thicknessAttenuation = exp(-absorption * thicknessFactor);
    }
    
    vec3 fresnelRefraction = schlickFresnel(specularColorReflection, dotNV);
    vec3 transmittedLight = linearAlbedo * thicknessAttenuation * (vec3(1.0) - fresnelRefraction);
    
    baseLighting = mix(baseLighting, baseLighting + transmittedLight, transmissionFactor * (1.0 - metalnessFactor));
  }

  // --- EVALUATE EMISSIVE CHANNEL MAPS ---
  if (hasEmissiveMap) {
    vec3 emissiveSample = texture(emissiveMap, v_uv).rgb;
    baseLighting += material.emissiveColor.rgb * emissiveSample * material.materialParams.w; 
  }

  // --- INTEGRATE CLEARCOAT PROTECTION SURFACE COATING LAYER ---
  if (clearcoatFactor > 0.0) {
    float clearcoatF0 = 0.04;
    float clearcoatFresnel = clearcoatF0 + (1.0 - clearcoatF0) * pow(1.0 - dotClearcoatNV, 5.0);
    
    float safeRoughness = max(clearcoatRoughness, 0.04);
    vec3 clearcoatSpecular = vec3(pow(dotClearcoatNV, 1.0 / safeRoughness));
    clearcoatSpecular = clamp(clearcoatSpecular, vec3(0.0), vec3(5.0)); // Prevent hot spots
    
    float factor = clearcoatFactor * clearcoatFresnel;
    baseLighting = baseLighting * vec3(1.0 - factor) + (clearcoatSpecular * factor);
  }

  // --- POST-PROCESSING ENGINES & COLORSPACE CONVERSION ---
  baseLighting = applyFog(baseLighting, v_worldPosition);
  vec4 finalRGBA = vec4(baseLighting, alpha);
  finalRGBA = applyColor(finalRGBA, material.lineExtendedParams.z);

  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
