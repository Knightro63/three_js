import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> phong = [ 
  ShaderChunk(
    name: 'material.phong.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}

struct PhongVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) worldPosition: vec3<f32>, // Safely placed at location(2) to avoid UV conflicts
    @location(2) worldNormal: vec3<f32>,   
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.phong.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.phong.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> PhongVertexOutput {
    var output: PhongVertexOutput;
    var position = input.position;
    var normal = input.normal;
    var vertexColor = input.color;

    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    let worldPosition4 = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition4.xyz;

    // Pass the world normal down for per-pixel calculations
    output.worldNormal = normalize((uniforms.modelMatrix * vec4<f32>(normal, 0.0)).xyz);
    
    let viewPosition = uniforms.scene.viewMatrix * worldPosition4;
    output.position = uniforms.scene.projectionMatrix * viewPosition;

    output.color = uniforms.baseColor.rgb * vertexColor;
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.phong.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct PhongFragmentInput {
    @location(0) color: vec3<f32>,
    @location(1) worldPosition: vec3<f32>, 
    @location(2) worldNormal: vec3<f32>, 
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.phong.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.lights>
#include <common.fog>
#include <common.color>
#include <common.clipping>
#include <common.flat_shading>
#include <material.phong.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: PhongFragmentInput) -> @location(0) vec4<f32> {
    evaluateClippingPlanes(input.worldPosition);
    var color = input.color;
    var alphaOverride = uniforms.baseColor.a;

    let N = evaluateNormal(input.worldNormal, input.worldPosition);
    let V = normalize(uniforms.scene.cameraPosition.xyz - input.worldPosition);

    {{FRAGMENT_INIT_EXTRA}}
    {{FRAGMENT_EXTRA}}

    // 1. Convert incoming color space to linear alignment
    let linearAlbedo = sRGBTransferEETF(vec4<f32>(color, 1.0)).rgb;

    // FIX: Extract material specular properties out of the uniform blocks
    let shininess = uniforms.materialParams.x; 
    let specularColor = uniforms.specularAndIOR.rgb;

    // 2. Pass all 6 arguments to match your new dynamic lights definition!
    var finalColor = calculateDynamicLighting(N, V, input.worldPosition, linearAlbedo, shininess, specularColor);

    // 3. Apply the environmental fog factor
    finalColor = applyFog(finalColor, input.worldPosition);

    var finalRGBA = vec4<f32>(finalColor, alphaOverride);
    
    // 4. Transform into the requested Output Color Space
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}
    ''',
  ),
];
