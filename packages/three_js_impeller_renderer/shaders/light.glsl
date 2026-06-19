struct IncidentLight {
    vec3 color;
    vec3 direction;
    bool visible;
};

struct ReflectedLight {
    vec3 diffuse;
    vec3 specular;
};

// WGSL pointers (ptr<function, T>) map directly to GLSL's performant 'inout' references
void RE_Direct_BlinnPhong(
  IncidentLight directLight, 
  vec3 N, 
  vec3 V, 
  vec3 albedo, 
  float shininess, 
  vec3 specularColor, 
  inout ReflectedLight reflectedLight
) {
  float dotNL = max(dot(N, directLight.direction), 0.0);

  reflectedLight.diffuse += directLight.color * albedo * dotNL;
  
  if (dotNL > 0.0 && directLight.visible) {
    if (shininess > 0.0) {
      vec3 H = normalize(directLight.direction + V);
      float dotNH = max(dot(N, H), 0.0);
      float specPower = pow(dotNH, max(shininess, 1.0));
      reflectedLight.specular += directLight.color * specularColor * specPower;
    }
  }
}

vec3 calculateDynamicLighting(
    vec3 N, 
    vec3 V, 
    vec3 worldPos, 
    vec3 albedo, 
    float shininess, 
    vec3 specularColor
) {
    // Explicit structural initializations using GLSL data type constructors
    ReflectedLight reflected = ReflectedLight(vec3(0.0), vec3(0.0));
    int totalLights = min(int(scene.cameraPosition.w), 16);
    vec3 ambientAccum = vec3(0.0);

    for (int i = 0; i < totalLights; i++) {
        // Accessing structural uniform buffer array blocks natively
        float typeToken = scene.lightPositions[i].w;
        float intensity = scene.lightColors[i].a;

        if (typeToken == 0.0) {
            // 0.0 = No Light / Unassigned Padding. Skip safely!
            continue;
        } 
        else if (typeToken == 6.0) {
            // AMBIENT LIGHT SOURCE TRACKING
            ambientAccum += scene.lightColors[i].rgb * intensity;
        } 
        else if (typeToken == 1.0) {
            // DIRECTIONAL LIGHT
            IncidentLight directLight = IncidentLight(vec3(0.0), vec3(0.0), false);
            directLight.direction = normalize(-scene.lightPositions[i].xyz);
            directLight.color = scene.lightColors[i].rgb * intensity;
            directLight.visible = true;
            
            RE_Direct_BlinnPhong(directLight, N, V, albedo, shininess, specularColor, reflected);
        } 
        else if (typeToken == 2.0) {
            // POINT LIGHT
            IncidentLight directLight = IncidentLight(vec3(0.0), vec3(0.0), false);
            vec3 lightWorldPos = scene.lightPositions[i].xyz;
            
            if (dot(lightWorldPos, lightWorldPos) == 0.0) {
                lightWorldPos = scene.cameraPosition.xyz;
            }
            
            vec3 lightToVertex = lightWorldPos - worldPos;
            float distanceToLight = length(lightToVertex);
            float lightDistance = scene.lightAttenuationParams[i].x;
            float lightDecay = scene.lightAttenuationParams[i].y;

            if (lightDistance == 0.0 || distanceToLight <= lightDistance) {
                directLight.direction = normalize(lightToVertex);
                float attenuation = 1.0;
                
                if (lightDistance > 0.0) {
                    attenuation = clamp(1.0 - pow(distanceToLight / lightDistance, lightDecay), 0.0, 1.0);
                } else {
                    attenuation = 1.0 / (1.0 + (distanceToLight * 0.002) * (distanceToLight * 0.002));
                }
                
                directLight.color = scene.lightColors[i].rgb * intensity * attenuation;
                directLight.visible = true;
                
                RE_Direct_BlinnPhong(directLight, N, V, albedo, shininess, specularColor, reflected);
            }
        } 
        else if (typeToken == 3.0) {
            // SPOT LIGHT
            IncidentLight directLight = IncidentLight(vec3(0.0), vec3(0.0), false);
            vec3 lightToVertex = scene.lightPositions[i].xyz - worldPos;
            float distanceToLight = length(lightToVertex);
            float lightDistance = scene.lightAttenuationParams[i].x;
            float lightDecay = scene.lightAttenuationParams[i].y;
            float coneAngle = scene.lightAttenuationParams[i].z;
            float conePenumbra = scene.lightAttenuationParams[i].w;

            if (lightDistance == 0.0 || distanceToLight <= lightDistance) {
                vec3 L = normalize(lightToVertex);
                vec3 spotDirection = normalize(scene.lightExtendedParams[i].xyz);
                float angleCos = dot(L, -spotDirection);
                float coneCos = cos(coneAngle);
                float penumbraCos = cos(coneAngle * (1.0 - conePenumbra));

                if (angleCos > coneCos) {
                    float attenuation = 1.0;
                    if (lightDistance > 0.0) {
                        attenuation = clamp(1.0 - pow(distanceToLight / lightDistance, lightDecay), 0.0, 1.0);
                    } else {
                        attenuation = 1.0 / (1.0 + (distanceToLight * 0.002) * (distanceToLight * 0.002));
                    }
                    
                    float spotEffect = smoothstep(coneCos, penumbraCos, angleCos);
                    directLight.direction = L;
                    directLight.color = scene.lightColors[i].rgb * intensity * attenuation * spotEffect;
                    directLight.visible = true;
                    
                    RE_Direct_BlinnPhong(directLight, N, V, albedo, shininess, specularColor, reflected);
                }
            }
        } 
        else if (typeToken == 4.0) {
            // HEMISPHERE LIGHT
            float dotNL = dot(N, normalize(scene.lightPositions[i].xyz));
            float hemiMix = dotNL * 0.5 + 0.5;
            vec3 skyColor = scene.lightColors[i].rgb * intensity;
            vec3 groundColor = scene.lightExtendedParams[i].xyz;
            ambientAccum += mix(groundColor, skyColor, hemiMix);
        }
    }

    vec3 emissiveRGB = material.emissiveColor.rgb;
    float emissiveIntensity = material.emissiveColor.a;
    vec3 emissiveContribution = emissiveRGB * emissiveIntensity;

    return (ambientAccum * albedo) + reflected.diffuse + reflected.specular + emissiveContribution;
}
