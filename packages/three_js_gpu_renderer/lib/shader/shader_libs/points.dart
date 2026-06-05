import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> points = [ 
  ShaderChunk(
    name: 'material.points.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) color: vec3<f32>, 
    {{VERTEX_INPUT_EXTRA}}
}

struct PointsVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(2) worldPosition: vec3<f32>, // Safely passes coordinates down to fog loops
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.points.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.points.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> PointsVertexOutput {
    var output: PointsVertexOutput;
    var position = input.position;
    var vertexColor = input.color;

    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition.xyz;
    
    output.position = uniforms.scene.projectionMatrix * uniforms.scene.viewMatrix * worldPosition;
    
    // NOTE: WebGPU natively enforces a static hardware width of 1 pixel for point topologies.
    // Specular size and distance-decay scale logic can be safely dropped here.

    output.color = uniforms.baseColor.rgb * vertexColor;
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.points.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct PointsFragmentInput {
    @location(0) color: vec3<f32>,
    @location(2) worldPosition: vec3<f32>, 
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.points.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.fog>
#include <common.color>
#include <material.points.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: PointsFragmentInput) -> @location(0) vec4<f32> {
    var color = input.color; 

    {{FRAGMENT_INIT_EXTRA}} 
    {{FRAGMENT_EXTRA}} 

    // Apply smooth environmental fog tracking matching your setup limits
    var finalColor = applyFog(color, input.worldPosition);

    var finalRGBA = vec4<f32>(finalColor, uniforms.baseColor.a);
    
    // Run central color space encoding rules (sRGB / Display P3)
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}
    ''',
  ),
];
