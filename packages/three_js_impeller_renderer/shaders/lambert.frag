#include <common.glsl>
#include <light.glsl>
#include <fog.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <flat_shading.glsl>

uniform sampler2D map;
uniform sampler2D alphaMap;
uniform sampler2D specularMap;
uniform sampler2D ormMap;
uniform sampler2D lightMap;

in vec3 v_color;
in vec2 v_uv;
in vec3 v_worldPosition;
in vec3 v_worldNormal;

out vec4 frag_color;

void main() {
  if(evaluateClippingPlanes(v_worldPosition)){
    frag_color = vec4(0.0);
    return;
  }
  bool hasMap         = material.flags0.y > 0.5; // TextureType.map
  bool hasAlphaMap    = material.flags0.z > 0.5; // TextureType.alphaMap
  bool hasSpecularMap = material.flags0.w > 0.5; // TextureType.specularMap
  bool hasAoMap       = material.flags1.x > 0.5; // TextureType.aoMap
  bool hasLightMap    = material.flags1.y > 0.5; // TextureType.lightMap

  vec4 texelColor = vec4(1.0); // Default neutral fallback configuration
  float alphaOverride = material.baseColor.a;

  if (hasMap) {
    texelColor = texture(map, v_uv);
    alphaOverride = material.baseColor.a * texelColor.a;
  }

  // Blend vertex attribute colors with your diffuse albedo map color
  vec3 blendedAlbedo = v_color * texelColor.rgb;

  // 4. Alpha Map Modifier Processing
  float alpha = alphaOverride;
  if (hasAlphaMap) {
    float extraAlpha = texture(alphaMap, v_uv).g; // Three.js reads the green channel
    alpha *= extraAlpha;
  }

  if (alpha < 0.001) {
    frag_color = vec4(0.0);
    return;
  }

  // 5. Ambient Occlusion (AO) Processing
  if (hasAoMap) {
    float ao = texture(ormMap, v_uv).r; // Grayscale shadow stored in red channel
    blendedAlbedo *= ao;
  }

  // 6. Baked Light Map Processing
  if (hasLightMap) {
    vec3 lightMapColor = texture(lightMap, v_uv).rgb;
    // Multiply by internal scale factor passed from your Float32List mapIntensities
    blendedAlbedo += lightMapColor * material.mapIntensities.z; 
  }

  // 7. Specular Map Intensity Processing
  vec3 specularColorReflection = vec3(0.0);
  if (hasSpecularMap) {
    specularColorReflection = texture(specularMap, v_uv).rgb;
  }

  // 8. Color Space Transition Room
  // Convert incoming base albedo into working Linear space for safe physics calculations
  vec3 linearAlbedo = sRGBTransferEETF(vec4(blendedAlbedo, 1.0)).rgb;

  // 9. Surface & Vector Math Extractions
  vec3 N = evaluateNormal(v_worldNormal, v_worldPosition);
  vec3 V = normalize(scene.cameraPosition.xyz - v_worldPosition);

  // 10. Multi-Light Pipeline Compilation
  // Pass diffuse properties, roughness (0.0 for Lambert), and your sampled reflections
  vec3 finalColor = calculateDynamicLighting(N, V, v_worldPosition, linearAlbedo, 0.0, specularColorReflection);

  // 11. Post-Lighting Environment Layers Integration
  finalColor = applyFog(finalColor, v_worldPosition);
  vec4 finalRGBA = vec4(finalColor, alpha);
  
  // Transform from working Linear space back to destination Output Space
  finalRGBA = applyColor(finalRGBA,material.lineExtendedParams.z);

  // 12. Output final safe frame register metrics
  frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), finalRGBA.a);
}
