import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> toon = [ 
  ShaderChunk(
    name: 'material.toon.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}

struct ToonVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) worldPosition: vec3<f32>, // Safe slot 2
    @location(2) worldNormal: vec3<f32>,   // Safe slot 3
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.toon.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.toon.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> ToonVertexOutput {
    var output: ToonVertexOutput;
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
    name: 'material.toon.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct ToonFragmentInput {
    @location(0) color: vec3<f32>,
    @location(1) worldPosition: vec3<f32>, 
    @location(2) worldNormal: vec3<f32>, 
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.toon.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.lights>
#include <common.fog>
#include <common.color>
#include <common.flat_shading>
#include <common.clipping>
#include <material.toon.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: ToonFragmentInput) -> @location(0) vec4<f32> {
    evaluateClippingPlanes(input.worldPosition);
    var color = input.color;
    var alphaOverride = uniforms.baseColor.a;
    
    // Evaluate normal using the flat shading chunk function
    let N = evaluateNormal(input.worldNormal, input.worldPosition);
    let V = normalize(uniforms.scene.cameraPosition.xyz - input.worldPosition);

    {{FRAGMENT_INIT_EXTRA}} 
    {{FRAGMENT_EXTRA}} 

    let linearAlbedo = sRGBTransferEETF(vec4<f32>(color, 1.0)).rgb;

    // Calculate light accumulation via unified multi-light loop array (no shininess for base cel shading diffuse)
    var litLighting = calculateDynamicLighting(N, V, input.worldPosition, linearAlbedo, 0.0, vec3<f32>(0.0));

    // Dynamic Posterized Quantization
    var steps = uniforms.pbrParams.y; // Track cartoon levels slider from Dart
    if (steps < 2.0) {
        steps = 3.0; 
    }
    litLighting = floor(litLighting * steps) / (steps - 1.0);

    var finalColor = applyFog(litLighting, input.worldPosition);
    var finalRGBA = vec4<f32>(finalColor, alphaOverride);
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}
    ''',
  ),
];
