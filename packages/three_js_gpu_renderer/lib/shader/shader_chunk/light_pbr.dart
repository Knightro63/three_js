import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const  ShaderChunk lightPbrChunk = ShaderChunk(
  name: 'lights.pbr',
  stage: ShaderStageType.fragment,
  source: '''
// 1. GGX/Towbridge-Reitz Normal Distribution Function (Specularity shape)
// Parity with WebGL: D_GGX(dotNH, roughness)
fn ndfGGX(dotNH: f32, roughness: f32) -> f32 {
    let a = roughness * roughness;
    let a2 = a * a;
    let denom = (dotNH * dotNH * (a2 - 1.0) + 1.0);
    return a2 / (3.14159265359 * denom * denom);
}

// 2. Schlick-GGX Geometry Smith Function (Self-shadowing microfacets)
// Parity with WebGL: G_Schlick_Smith(dotNL, dotNV, roughness)
fn gaSchlickG1(dotNX: f32, k: f32) -> f32 {
    return dotNX / (dotNX * (1.0 - k) + k);
}

fn geometrySmith(dotNL: f32, dotNV: f32, roughness: f32) -> f32 {
    let r = roughness + 1.0;
    let k = (r * r) / 8.0; // Analytical mapping factor for analytical light sources
    return gaSchlickG1(dotNL, k) * gaSchlickG1(dotNV, k);
}

// 3. Fresnel Schlick Equation (Reflective properties based on viewing angle)
// Parity with WebGL: F_Schlick(cosTheta, F0)
fn fresnelSchlick(cosTheta: f32, F0: vec3<f32>) -> vec3<f32> {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

fn calculatePhongLighting(N: vec3<f32>, V: vec3<f32>, worldPos: vec3<f32>, albedo: vec3<f32>) -> vec3<f32> {
    // 1. Initialize ambient component using your dynamic scene environment buffer
    var diffuseAccum = uniforms.scene.ambientColor.rgb * albedo;
    var specularAccum = vec3<f32>(0.0);
    
    let totalLights = i32(uniforms.scene.cameraPosition.w);
    
    // 2. Loop explicitly through active analytical light sources
    for (var i = 0; i < totalLights; i = i + 1) {
        let light = uniforms.scene.lights[i];
        
        // Invert the light direction vector to point from the surface toward the light source
        let L = normalize(-light.positionOrDirection.xyz);
        
        // Diffuse Component calculation (Lambertian reflection)
        let dotNL = max(dot(N, L), 0.0);
        
        if (dotNL > 0.0) {
            // Accumulate incoming light intensity scaled by the albedo texture or base canvas color
            diffuseAccum += light.colorAndIntensity.rgb * albedo * dotNL * light.colorAndIntensity.a;
            
            // Specular Component calculation (Blinn-Phong halfway vector profile)
            let H = normalize(L + V);
            let dotNH = max(dot(N, H), 0.0);
            
            // Extract material shininess factor from the compact material parameters vector
            let shininess = uniforms.materialParams.x;
            let specPower = pow(dotNH, max(shininess, 1.0));
            
            // Multiply light intensity against your specialized specular highlight tint color
            specularAccum += light.colorAndIntensity.rgb * uniforms.specularAndIOR.rgb * specPower * light.colorAndIntensity.a;
        }
    }
    
    // Return combined illumination layers
    return diffuseAccum + specularAccum;
}
''',
);