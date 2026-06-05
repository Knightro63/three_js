import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> lineDashed = [ 
  ShaderChunk(
    name: 'material.lineDashed.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) color: vec3<f32>, 
    //@location(3) lineDistance: f32, // FIX 1: Explicitly capture incoming line distance buffer stream data
    {{VERTEX_INPUT_EXTRA}}
}

struct LineDashedVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) vLineDistance: f32,    // FIX 2: Shifted to location(2) to safely clear room for injected UVs
    @location(2) worldPosition: vec3<f32>, // Added location(3) to support world distance fog calculations
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.lineDashed.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.lineDashed.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> LineDashedVertexOutput {
    var output: LineDashedVertexOutput;
    var position = input.position;
    var vertexColor = input.color;

    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition.xyz;
    
    output.position = uniforms.scene.projectionMatrix * uniforms.scene.viewMatrix * worldPosition;
    
    // FIX 3: Read from the valid input field assignment instead of a broken uv structure
    output.vLineDistance = 2.0;//input.lineDistance;
    
    output.color = uniforms.baseColor.rgb * vertexColor;
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.lineDashed.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct LineDashedFragmentInput {
    @location(0) color: vec3<f32>,
    @location(1) vLineDistance: f32,    // FIX 2: Matched location(2) placement shifts
    @location(2) worldPosition: vec3<f32>, // Added location(3) varying to receive coordinates
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.lineDashed.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.fog>
#include <common.color>
#include <material.lineDashed.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: LineDashedFragmentInput) -> @location(0) vec4<f32> {
    var color = input.color; 

    {{FRAGMENT_INIT_EXTRA}} 

    // Extract dash and gap configurations from your custom lineParams vector uniform block offsets
    var dashSize = uniforms.lineParams.y; // line.dashSize mapped from your Dart file setup attributes
    var gapSize = uniforms.lineExtendedParams.x;  // line.gapSize mapped from your Dart file setup attributes
    
    if (dashSize <= 0.0) {
        dashSize = 3.0; 
    }
    if (gapSize <= 0.0) {
        gapSize = 1.0; 
    }
    
    let totalSize = dashSize + gapSize;
    
    // FIX 4: Corrected float modulo implementation bypassing WGSL integer limitation bounds
    // Equation: x - y * floor(x / y)
    let moduloDistance = input.vLineDistance - totalSize * floor(input.vLineDistance / totalSize);
    
    if (moduloDistance > dashSize) {
        discard; // Instantly kills execution for pixel fragments hitting occlusion gap spaces
    }

    {{FRAGMENT_EXTRA}} 

    // Apply dynamic environmental fog tracking matching your setup limits
    var finalColor = applyFog(color, input.worldPosition);

    var finalRGBA = vec4<f32>(finalColor, uniforms.baseColor.a);
    
    // Run central color space encoding rules (sRGB / Display P3)
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}
    ''',
  ),
];
