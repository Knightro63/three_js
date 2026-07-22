#include <material_block.glsl>
#include <scene_block.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <tonemapping.glsl>

uniform sampler2D map;          
uniform sampler2D alphaMap;     
uniform sampler2D ormMap;        
uniform sampler2D specularMap;  

in vec3 v_color; 
in vec3 v_worldPosition; 
in vec2 v_uv; 

out vec4 frag_color;

void main() {
  vec4 diffuseColor = vec4(v_color,material.baseColor.a);
  applyClippingPlanes(diffuseColor,v_worldPosition);

  vec3 color = diffuseColor.rgb;
  float alphaOverride = diffuseColor.a;

  // 1. Albedo Processing
  vec4 texelColor = vec4(1.0); // Default fallback: neutral white
  if (material.flags0.y > 0.5) {
    texelColor = texture(map, v_uv);
    alphaOverride = material.baseColor.a * texelColor.a;
  }
  else{
    alphaOverride = material.baseColor.a;
  }
  vec3 baseColor = color * texelColor.rgb;

  // 2. Ambient Occlusion Processing
  if (material.flags0.z > 0.5) {
    float ao = texture(ormMap, v_uv).r;
    baseColor *= ao; 
  }

  // 3. Specular Processing
  vec3 specularIntensity = vec3(0.0); // Default fallback: no extra shine
  if (material.flags0.w > 0.5) {
    specularIntensity = texture(specularMap, v_uv).rgb;
  }

  // 4. Alpha Processing
  float alpha = alphaOverride;
  if (material.flags1.x > 0.5) {
    float extraAlpha = texture(alphaMap, v_uv).g;
    alpha *= extraAlpha;
  }

  if (alpha < 0.001) {
    discard;
  }

  // 5. Final Output Compilation
  vec3 finalColor = applyFog( baseColor,  v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);
  finalRGBA = applyColor(finalRGBA,scene.rendParms.z);
  finalRGBA.rgb = toneMapping(finalRGBA.rgb);

  frag_color = vec4(clamp(finalRGBA.rgb,vec3(0.0),vec3(1.0)), finalRGBA.a);
}
