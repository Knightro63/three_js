import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const  ShaderChunk lightPhong= ShaderChunk(
  name: 'light.phong',
  stage: ShaderStageType.fragment,
  source: '''
fn calculatePhongLighting(N: vec3<f32>, V: vec3<f32>, worldPos: vec3<f32>, albedo: vec3<f32>) -> vec3<f32> { 
    var diffuseAccum = vec3<f32>(0.0); 
    var specularAccum = vec3<f32>(0.0); 
    
    // Read total light count from cameraPosition.w
    let totalLights = i32(uniforms.scene.cameraPosition.w); 
    
    for (var i = 0; i < totalLights; i = i + 1) { 
        let light = uniforms.scene.lights[i]; 
        
        // FIX: Replicate Three.js handling of positional vs directional lights using light.position.w
        var L = vec3<f32>(0.0);
        if (light.position.w == 0.0) {
            // It's a Directional Light! The value is an inverse direction vector.
            L = normalize(-light.position.xyz); 
        } else {
            // It's a Point/Spot Light! Calculate distance direction vector relative to surface.
            L = normalize(light.position.xyz - worldPos);
        }
        
        let dotNL = max(dot(N, L), 0.0); 
        if (dotNL > 0.0) { 
            // Extract intensity from color.a as defined in your struct comments
            let intensity = light.color.a;
            
            // 1. Diffuse (Lambertian)
            diffuseAccum += light.color.rgb * intensity * albedo * dotNL; 
            
            // 2. Specular (Blinn-Phong)
            let H = normalize(L + V); 
            let dotNH = max(dot(N, H), 0.0); 
            
            let shininess = uniforms.materialParams.x; 
            let specPower = pow(dotNH, max(shininess, 1.0)); 
            
            specularAccum += light.color.rgb * intensity * uniforms.specularAndIOR.rgb * specPower; 
        } 
    } 
    return diffuseAccum + specularAccum; 
}

  ''',
);