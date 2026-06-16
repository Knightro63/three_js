#include <common.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <flat_shading.glsl>

uniform sampler2D map;
uniform sampler2D alphaMap;
uniform sampler2D matcap;

in vec3 v_color;
in vec3 v_worldPosition;
in vec3 v_worldNormal;
in vec2 v_uv;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    frag_color = vec4(0.0);
    return;
  }
    
  bool hasMap         = material.flags0.y > 0.5; // TextureType.map
  bool hasAlphaMap    = material.flags0.z > 0.5; // TextureType.alphaMap
  bool hasMatcap      = material.flags5.z > 0.5; // TextureType.matcap (Index 114)

  vec4 texelColor = vec4(1.0); // Neutral fallback
  float alphaOverride = material.baseColor.a;

  if (hasMap) {
    texelColor = texture(map, v_uv);
    alphaOverride = material.baseColor.a * texelColor.a;
  }

  vec3 baseColor = v_color * texelColor.rgb;

  float alpha = alphaOverride;
  if (hasAlphaMap) {
    alpha *= texture(alphaMap, v_uv).g; // Samples the green channel
  }

  if (alpha < 0.001) {
    frag_color = vec4(0.0);
    return;
  }

  vec3 N = evaluateNormal(v_worldNormal, v_worldPosition);

  mat4 modelViewMatrix = scene.viewMatrix * material.modelMatrix;
  mat3 normalMatrix = mat3(modelViewMatrix);
  vec3 viewNormal = normalize(normalMatrix * N);

  vec2 matcapUv = viewNormal.xy * 0.5 + vec2(0.5);
  matcapUv.y = 1.0 - matcapUv.y; // Invert vertical axis to map standard WebGL layouts

  vec3 matcapColor = vec3(1.0); // Default fallback
  if (hasMatcap) {
    matcapColor = texture(matcap, matcapUv).rgb;
  }

  vec3 finalColor = baseColor * matcapColor;

  finalColor = applyFog(finalColor, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);

  // Run central color space grading rules
  finalRGBA = applyColor(finalRGBA);

  // float antiPrune = texture(normalMap, vec2(0.0)).r * 0.000001 + 
  //                   texture(bumpMap, vec2(0.0)).r * 0.000001;

  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a);// + vec3(antiPrune)
}
