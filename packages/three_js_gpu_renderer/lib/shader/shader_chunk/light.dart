import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const ShaderChunk lightsChunk = ShaderChunk(
  name: 'common.lights',
  source: '''
struct IncidentLight {
    color: vec3<f32>,
    direction: vec3<f32>,
    visible: bool,
};

struct ReflectedLight {
    diffuse: vec3<f32>,
    specular: vec3<f32>,
};

fn RE_Direct_BlinnPhong(directLight: IncidentLight, N: vec3<f32>, V: vec3<f32>, albedo: vec3<f32>, shininess: f32, specularColor: vec3<f32>, reflectedLight: ptr<function, ReflectedLight>) {
    let dotNL = max(dot(N, directLight.direction), 0.0);
    
    if (dotNL > 0.0 && directLight.visible) {
        (*reflectedLight).diffuse += directLight.color * albedo * dotNL;
        
        if (shininess > 0.0) {
            let H = normalize(directLight.direction + V);
            let dotNH = max(dot(N, H), 0.0);
            let specPower = pow(dotNH, max(shininess, 1.0));
            
            (*reflectedLight).specular += directLight.color * specularColor * specPower;
        }
    }
}

fn calculateDynamicLighting(N: vec3<f32>, V: vec3<f32>, worldPos: vec3<f32>, albedo: vec3<f32>, shininess: f32, specularColor: vec3<f32>) -> vec3<f32> {
    var reflected = ReflectedLight(vec3<f32>(0.0), vec3<f32>(0.0));
    let totalLights = min(i32(uniforms.scene.cameraPosition.w), 16);
    
    var ambientAccum = vec3<f32>(0.0);

    for (var i = 0; i < totalLights; i = i + 1) {
        let light = uniforms.scene.lights[i];
        let typeToken = light.position.w; 
        let intensity = light.color.a;

        if (typeToken == 0.0) {
            // 0.0 = No Light / Unassigned Padding. Skip safely!
            continue; 
            
        } else if (typeToken == 6.0) {
            // ==========================================
            // AMBIENT LIGHT SOURCE TRACKING (Token 6.0)
            // ==========================================
            ambientAccum += light.color.rgb * intensity;

        } else if (typeToken == 1.0) {
            // DIRECTIONAL LIGHT
            var directLight = IncidentLight(vec3<f32>(0.0), vec3<f32>(0.0), false);
            directLight.direction = normalize(-light.position.xyz);
            directLight.color = light.color.rgb * intensity;
            directLight.visible = true;
            
            RE_Direct_BlinnPhong(directLight, N, V, albedo, shininess, specularColor, &reflected);

        } else if (typeToken == 2.0) {
            // POINT LIGHT
            var directLight = IncidentLight(vec3<f32>(0.0), vec3<f32>(0.0), false);
            var lightWorldPos = light.position.xyz;
            
            if (dot(lightWorldPos, lightWorldPos) == 0.0) {
                lightWorldPos = uniforms.scene.cameraPosition.xyz;
            }

            let lightToVertex = lightWorldPos - worldPos;
            let distanceToLight = length(lightToVertex);
            let lightDistance = light.attenuationParams.x; 
            let lightDecay = light.attenuationParams.y;    

            if (lightDistance == 0.0 || distanceToLight <= lightDistance) {
                directLight.direction = normalize(lightToVertex);
                
                var attenuation = 1.0;
                if (lightDistance > 0.0) {
                    attenuation = clamp(1.0 - pow(distanceToLight / lightDistance, lightDecay), 0.0, 1.0);
                } else {
                    attenuation = 1.0 / (1.0 + (distanceToLight * 0.002) * (distanceToLight * 0.002));
                }
                
                directLight.color = light.color.rgb * intensity * attenuation;
                directLight.visible = true;
                
                RE_Direct_BlinnPhong(directLight, N, V, albedo, shininess, specularColor, &reflected);
            }

        } else if (typeToken == 3.0) {
            // SPOT LIGHT
            var directLight = IncidentLight(vec3<f32>(0.0), vec3<f32>(0.0), false);
            let lightToVertex = light.position.xyz - worldPos;
            let distanceToLight = length(lightToVertex);
            let lightDistance = light.attenuationParams.x;
            let lightDecay = light.attenuationParams.y;
            let coneAngle = light.attenuationParams.z;      
            let conePenumbra = light.attenuationParams.w;   

            if (lightDistance == 0.0 || distanceToLight <= lightDistance) {
                let L = normalize(lightToVertex);
                let spotDirection = normalize(light.extendedParams.xyz); 
                let angleCos = dot(L, -spotDirection);
                let coneCos = cos(coneAngle);
                let penumbraCos = cos(coneAngle * (1.0 - conePenumbra));

                if (angleCos > coneCos) {
                    var attenuation = 1.0;
                    if (lightDistance > 0.0) {
                        attenuation = clamp(1.0 - pow(distanceToLight / lightDistance, lightDecay), 0.0, 1.0);
                    } else {
                        attenuation = 1.0 / (1.0 + (distanceToLight * 0.002) * (distanceToLight * 0.002));
                    }
                    
                    let spotEffect = smoothstep(coneCos, penumbraCos, angleCos);
                    
                    directLight.direction = L;
                    directLight.color = light.color.rgb * intensity * attenuation * spotEffect;
                    directLight.visible = true;
                    
                    RE_Direct_BlinnPhong(directLight, N, V, albedo, shininess, specularColor, &reflected);
                }
            }

        } else if (typeToken == 4.0) {
            // HEMISPHERE LIGHT
            let dotNL = dot(N, normalize(light.position.xyz));
            let hemiMix = dotNL * 0.5 + 0.5;
            let skyColor = light.color.rgb * intensity;
            let groundColor = light.extendedParams.xyz; 
            
            ambientAccum += mix(groundColor, skyColor, hemiMix);
        }
    }

    let emissiveRGB = uniforms.emissiveColor.rgb;
    let emissiveIntensity = uniforms.emissiveColor.a;
    let emissiveContribution = emissiveRGB * emissiveIntensity;

    // 2. Add the emissive glowing layer directly to your final composition paths!
    return (ambientAccum * albedo) + reflected.diffuse + reflected.specular + emissiveContribution;
}
  ''',
);
