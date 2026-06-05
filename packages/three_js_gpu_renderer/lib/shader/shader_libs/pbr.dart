import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> pbr = [ 
  ShaderChunk(
    name: 'material.pbr.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct PbrVertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    //@location(3) uv: vec2<f32>,            
    {{VERTEX_INPUT_EXTRA}}
}

struct PbrVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(2) worldNormal: vec3<f32>,   
    @location(3) viewDir: vec3<f32>,       
    @location(4) albedo: vec3<f32>,        
    @location(5) worldPosition: vec3<f32>, 
    @location(6) vUv: vec2<f32>,           
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.pbr.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.pbr.vertex.input>

@vertex
fn vs_main(input: PbrVertexInput) -> PbrVertexOutput {
    var output: PbrVertexOutput;
    var position = input.position;
    var normal = input.normal;
    
    var vertexColor = input.color;
    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    // Capture the 4x4 matrix object out of the uniform structure locally
    let modelMat = uniforms.modelMatrix;

    let worldPosition = modelMat * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition.xyz;
    
    let viewPosition = uniforms.scene.viewMatrix * worldPosition;
    output.position = uniforms.scene.projectionMatrix * viewPosition;

    // FIX: Access swizzles safely off the isolated modelMat matrix variable!
    let normalMatrix = mat3x3<f32>(
        modelMat[0].xyz,
        modelMat[1].xyz,
        modelMat[2].xyz
    );
    output.worldNormal = normalize(normalMatrix * normal);

    let cameraPos = uniforms.scene.cameraPosition.xyz;
    output.viewDir = cameraPos - worldPosition.xyz;

    output.albedo = uniforms.baseColor.rgb * vertexColor;
    output.vUv = input.uv;
    
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.pbr.fragment.bindings',
    stage: ShaderStageType.fragment,
    source: '''
@group(2) @binding(0) var prefilterTexture: texture_cube<f32>;
@group(2) @binding(1) var prefilterSampler: sampler;
@group(2) @binding(2) var brdfLutTexture: texture_2d<f32>;
@group(2) @binding(3) var brdfLutSampler: sampler;
    ''',
  ),
  ShaderChunk(
    name: 'material.pbr.fragment.functions',
    stage: ShaderStageType.fragment,
    source: '''
fn roughness_to_mip(roughness: f32, mipCount: f32) -> f32 {
    if (mipCount <= 1.0) {
        return 0.0;
    }
    let clamped = clamp(roughness, 0.0, 1.0);
    let perceptual = clamped * clamped;
    let maxLevel = mipCount - 1.0;
    return min(maxLevel, perceptual * maxLevel);
}

fn saturate(value: f32) -> f32 {
    return clamp(value, 0.0, 1.0);
}
    ''',
  ),
  ShaderChunk(
    name: 'material.pbr.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct PbrFragmentInput {
    @location(2) worldNormal: vec3<f32>,
    @location(3) viewDir: vec3<f32>,
    @location(4) albedo: vec3<f32>,
    @location(5) worldPosition: vec3<f32>, 
    @location(6) vUv: vec2<f32>,           
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.pbr.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <material.pbr.fragment.bindings>
#include <material.pbr.fragment.functions>
#include <material.pbr.fragment.input>

#include <common.lights>
#include <common.fog>
#include <common.color>
#include <common.clipping>
#include <common.flat_shading>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: PbrFragmentInput) -> @location(0) vec4<f32> {
    evaluateClippingPlanes(input.worldPosition);
    var baseColor = clamp(input.albedo, vec3<f32>(0.0), vec3<f32>(1.0));
    var alphaOverride = uniforms.baseColor.a;

    let N = evaluateNormal(input.worldNormal, input.worldPosition);
    let V = normalize(input.viewDir);
    
    {{FRAGMENT_INIT_EXTRA}}
    {{FRAGMENT_EXTRA}}

    baseColor = sRGBTransferEETF(vec4<f32>(baseColor, 1.0)).rgb;

    let roughness = uniforms.pbrParams.x;
    let metalness = uniforms.pbrParams.y;
    let envIntensity = uniforms.mapIntensities.y; 

    var reflection = vec3<f32>(0.0);
    var NdotV = saturate(dot(N, V));
    
    if (envIntensity > 0.0 && length(V) > 0.0) {
        let R = reflect(-V, N);
        let lod = roughness_to_mip(roughness, 5.0);
        let sampled = textureSampleLevel(prefilterTexture, prefilterSampler, R, lod);
        reflection = sampled.rgb;
    }
    
    let F0 = mix(vec3<f32>(0.04), baseColor, metalness);
    
    var indirectSpecular = vec3<f32>(0.0);
    if (envIntensity > 0.0) {
        // FIX: Replaced textureSample with textureSampleLevel. 
        // Passing 0.0 for the explicit mip-level lets us sample 32-bit float data safely!
        let brdfSample = textureSampleLevel(brdfLutTexture, brdfLutSampler, vec2<f32>(NdotV, roughness), 0.0).rg;
        
        indirectSpecular = reflection * (F0 * brdfSample.x + vec3<f32>(brdfSample.y)) * envIntensity;
    }

    let analyticalLighting = calculateDynamicLighting(N, V, input.worldPosition, baseColor, 0.0, vec3<f32>(0.0));
    var finalColor = indirectSpecular + analyticalLighting;

    finalColor = applyFog(finalColor, input.worldPosition);
    var finalRGBA = vec4<f32>(finalColor, alphaOverride);
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}
    ''',
  ),
];
