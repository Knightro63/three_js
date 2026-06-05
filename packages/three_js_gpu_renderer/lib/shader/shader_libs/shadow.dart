import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> shadow = [ 
  ShaderChunk(
    name: 'material.shadow.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}

struct ShadowVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(2) worldPosition: vec3<f32>, // Safe slot 2
    @location(3) worldNormal: vec3<f32>,   // Safe slot 3
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.shadow.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.shadow.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> ShadowVertexOutput {
    var output: ShadowVertexOutput;
    var position = input.position;
    var normal = input.normal;
    var vertexColor = input.color;

    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    let worldPosition4 = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition4.xyz;
    output.worldNormal = normalize((uniforms.modelMatrix * vec4<f32>(normal, 0.0)).xyz);
    
    let viewPosition = uniforms.scene.viewMatrix * worldPosition4;
    output.position = uniforms.scene.projectionMatrix * viewPosition;
    
    output.color = uniforms.baseColor.rgb * vertexColor;
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.shadow.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct ShadowFragmentInput {
    @location(0) color: vec3<f32>,
    @location(2) worldPosition: vec3<f32>, 
    @location(3) worldNormal: vec3<f32>, 
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.shadow.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.flat_shading>
#include <common.clipping>
#include <material.shadow.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: ShadowFragmentInput) -> @location(0) vec4<f32> {
    evaluateClippingPlanes(input.worldPosition);
    {{FRAGMENT_INIT_EXTRA}}

    // Evaluate normal per-pixel so shadow lines break sharply on flat low-poly triangles
    let N = evaluateNormal(input.worldNormal, input.worldPosition);
    
    var L = vec3<f32>(0.0, 1.0, 0.0); 
    let totalLights = i32(uniforms.scene.cameraPosition.w);
    
    if (totalLights > 0) {
        let mainLight = uniforms.scene.lights[0];
        let typeToken = mainLight.position.w;
        
        if (typeToken == 1.0) {
            L = normalize(-mainLight.position.xyz);
        } else {
            L = normalize(mainLight.position.xyz - input.worldPosition);
        }
    }
    
    let dotNL = dot(N, L);
    let shadowColor = vec3<f32>(0.0, 0.0, 0.0); 
    let shadowIntensity = clamp(1.0 - max(dotNL, 0.0), 0.0, 1.0); 
    let finalAlpha = shadowIntensity * uniforms.baseColor.a; 

    {{FRAGMENT_EXTRA}}

    return vec4<f32>(shadowColor, finalAlpha); 
}
    ''',
  ),
];
