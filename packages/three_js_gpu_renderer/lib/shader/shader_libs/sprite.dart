import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> sprite = [ 
  ShaderChunk(
    name: 'material.sprite.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) color: vec3<f32>, 
    {{VERTEX_INPUT_EXTRA}}
}

struct SpriteVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(2) worldPosition: vec3<f32>, // Safe slot 2
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.sprite.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.sprite.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> SpriteVertexOutput {
    var output: SpriteVertexOutput;
    var position = input.position;
    var vertexColor = input.color;

    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    // World billboard translation center point
    let worldPositionCenter = uniforms.modelMatrix * vec4<f32>(0.0, 0.0, 0.0, 1.0);
    let mvPosition = uniforms.scene.viewMatrix * worldPositionCenter;

    // Isolate scale variables out from columns 0 and 1
    let scaleX = length(uniforms.modelMatrix[0].xyz); 
    let scaleY = length(uniforms.modelMatrix[1].xyz); 

    let alignedPosition = mvPosition.xyz + vec3<f32>(position.x * scaleX, position.y * scaleY, 0.0);
    output.position = uniforms.scene.projectionMatrix * vec4<f32>(alignedPosition, 1.0);
    
    // Provide true world coordinates for distance fog lookups
    output.worldPosition = worldPositionCenter.xyz + vec3<f32>(position.x * scaleX, position.y * scaleY, 0.0);
    output.color = uniforms.baseColor.rgb * vertexColor;
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.sprite.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct SpriteFragmentInput {
    @location(0) color: vec3<f32>,
    @location(2) worldPosition: vec3<f32>, 
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.sprite.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.fog>
#include <common.color>
#include <material.sprite.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: SpriteFragmentInput) -> @location(0) vec4<f32> {
    var color = input.color;
    var alphaOverride = uniforms.baseColor.a;

    {{FRAGMENT_INIT_EXTRA}} 
    {{FRAGMENT_EXTRA}} 

    var finalColor = applyFog(color, input.worldPosition);
    var finalRGBA = vec4<f32>(finalColor, alphaOverride);
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}
    ''',
  ),
];
