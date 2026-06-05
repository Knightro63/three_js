import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> normal = [ 
  ShaderChunk(
    name: 'material.normal.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}

struct NormalVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(2) worldNormal: vec3<f32>,   // Passed forward to location(2)
    @location(3) worldPosition: vec3<f32>, // Passed forward to location(3) to support flat shading derivatives
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.normal.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.normal.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> NormalVertexOutput {
    var output: NormalVertexOutput;
    var position = input.position;
    var normal = input.normal;
    var vertexColor = input.color;

    {{VERTEX_ASSIGN_EXTRA}}

    let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition.xyz;
    output.position = uniforms.scene.projectionMatrix * uniforms.scene.viewMatrix * worldPosition;

    // Pass the raw world space vectors down to the fragment shader
    output.worldNormal = normalize((uniforms.modelMatrix * vec4<f32>(normal, 0.0)).xyz);
    output.color = vertexColor;
    
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.normal.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct NormalFragmentInput {
    @location(0) color: vec3<f32>,
    @location(2) worldNormal: vec3<f32>,   // Received safely on slot 2
    @location(3) worldPosition: vec3<f32>, // Received safely on slot 3
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.normal.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.color>
#include <common.clipping>
#include <common.flat_shading> // Injects your clean evaluateNormal() function!
#include <material.normal.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: NormalFragmentInput) -> @location(0) vec4<f32> {
    evaluateClippingPlanes(input.worldPosition);
    {{FRAGMENT_INIT_EXTRA}} 
    {{FRAGMENT_EXTRA}} 

    // 1. Evaluate your flat/smooth normal selector chunk on a per-pixel level
    let N_world = evaluateNormal(input.worldNormal, input.worldPosition);

    // 2. Transform the world space normal vector directly using the Scene View Matrix!
    // This shifts your normal coordinates into pure Camera Space.
    // We isolate the 3x3 orientation channels to completely strip out any matrix translation flags.
    let viewMat3x3 = mat3x3<f32>(
        uniforms.scene.viewMatrix[0].xyz,
        uniforms.scene.viewMatrix[1].xyz,
        uniforms.scene.viewMatrix[2].xyz
    );
    
    var viewNormal = normalize(viewMat3x3 * N_world);

    // 4. Map the [-1.0, 1.0] view vectors to standard [0.0, 1.0] RGB display values
    let packedColor = viewNormal * 1.0 + vec3<f32>(0.5);

    var finalRGBA = vec4<f32>(packedColor, 1.0);
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}

    ''',
  ),
];
