import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const ShaderChunk fogChunk = ShaderChunk(
  name: 'common.fog',
  source: '''
fn applyFog(baseColor: vec3<f32>, worldPos: vec3<f32>) -> vec3<f32> {
    // If scene.fogParams.x is <= 0.0, fog is disabled for this object
    if (uniforms.scene.fogParams.x <= 0.0) {
        return baseColor;
    }

    // 1. FIX: Calculate absolute distance from camera in World Space!
    // This completely avoids WebGL vs WebGPU View Matrix clipping plane discrepancies.
    let vFogDepth = distance(uniforms.scene.cameraPosition.xyz, worldPos);
    
    var fogFactor = 0.0;
    let fogNear = uniforms.scene.fogParams.x;
    let fogFar = uniforms.scene.fogParams.y;
    let fogDensity = uniforms.scene.fogParams.z;
    let isFogExp2 = uniforms.scene.fogParams.w; // 1.0 = Exp2 mode, 0.0 = Linear mode

    if (isFogExp2 > 0.5) {
        // Match GLSL: 1.0 - exp( - density * density * depth * depth )
        let d = fogDensity * vFogDepth;
        fogFactor = 1.0 - exp(-d * d);
    } else {
        // Match GLSL smoothstep(fogNear, fogFar, vFogDepth)
        let t = clamp((vFogDepth - fogNear) / (fogFar - fogNear), 0.0, 1.0);
        fogFactor = t * t * (3.0 - 2.0 * t);
    }

    // Smoothly blend the base canvas color into your background color channel
    return mix(baseColor, uniforms.scene.fogColor.rgb, fogFactor);
}
  ''',
);