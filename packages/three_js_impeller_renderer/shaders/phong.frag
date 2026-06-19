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
uniform sampler2D specularMap;
uniform sampler2D ormMap;
uniform sampler2D lightMap;

in vec3 v_color;
in vec3 v_worldPosition;
in vec3 v_worldNormal;
in vec2 v_uv;

out vec4 frag_color;

vec2 dXgrad(vec2 texUV) {
    return vec2(dFdx(texUV.x), dFdy(texUV.x));
}

vec2 dYgrad(vec2 texUV) {
    return vec2(dFdx(texUV.y), dFdy(texUV.y));
}

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
    frag_color = vec4(0.0);
    return;
  }

  bool hasMap         = material.flags0.y > 0.5;
  bool hasAlphaMap    = material.flags0.z > 0.5;
  bool hasSpecularMap = material.flags0.w > 0.5;
  bool hasAoMap       = material.flags1.x > 0.5;
  bool hasLightMap    = material.flags1.y > 0.5;
  bool hasNormalMap   = material.flags0.x > 0.5;
  bool hasBumpMap     = material.flags1.z > 0.5;

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

  if (alpha < 0.001) {
    frag_color = vec4(0.0);
    return;
  }

  if (hasAoMap) {
    blendedAlbedo *= texture(ormMap, v_uv).r;
  }

  if (hasLightMap) {
    blendedAlbedo += texture(lightMap, v_uv).rgb * material.mapIntensities.z;
  }

  vec3 specularColorReflection = material.specularAndIOR.rgb;
  if (hasSpecularMap) {
    specularColorReflection *= texture(specularMap, v_uv).rgb;
  }

  vec3 linearAlbedo = sRGBTransferEETF(vec4(blendedAlbedo, 1.0)).rgb;

  vec3 N = evaluateNormal(v_worldNormal, v_worldPosition);

  if (hasNormalMap) {
    vec3 normalMapSample = texture(normalMap, v_uv).xyz * 2.0 - 1.0;
    normalMapSample.xy *= material.mapIntensities.w;
    vec2 dHdxy = normalMapSample.xy;
    float faceDirection = gl_FrontFacing ? 1.0 : -1.0;
    N = perturbNormalArb(v_worldPosition, N, dHdxy, faceDirection);
  }
  else if (hasBumpMap) {
    float bumpSample = texture(bumpMap, v_uv).r;
    vec2 dHdxy = vec2(dFdx(bumpSample), dFdy(bumpSample)) * material.mapIntensities.x;
    float faceDirection = gl_FrontFacing ? 1.0 : -1.0;
    N = perturbNormalArb(v_worldPosition, N, dHdxy, faceDirection);
  }

  vec3 V = normalize(scene.cameraPosition.xyz - v_worldPosition);

  float shininess = material.materialParams.x;

  vec3 finalColor = calculateDynamicLighting(N, V, v_worldPosition, linearAlbedo, shininess, specularColorReflection);

  finalColor = applyFog(finalColor, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);

  finalRGBA = applyColor(finalRGBA,material.lineExtendedParams.z);

  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
