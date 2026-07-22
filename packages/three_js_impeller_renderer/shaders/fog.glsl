vec3 applyFog(vec3 baseColor, vec3 worldPos) {
  if (scene.fogParams.x <= 0.0) {
    return baseColor;
  }

  float vFogDepth = distance(material.cameraPosition.xyz, worldPos);
  float fogFactor = 0.0;
  
  float fogNear = scene.fogParams.x;
  float fogFar = scene.fogParams.y;
  float fogDensity = scene.fogParams.z;
  float isFogExp2 = scene.fogParams.w; // 1.0 = Exp2 mode, 0.0 = Linear mode

  if (isFogExp2 > 0.5) {
    float d = fogDensity * vFogDepth;
    fogFactor = 1.0 - exp(-d * d);
  } else {
    fogFactor = smoothstep(fogNear, fogFar, vFogDepth);
  }

  return mix(baseColor, scene.fogColor.rgb, fogFactor);
}
