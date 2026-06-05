import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> lambert = [ 
  ShaderChunk(
    name: 'material.lambert.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}

struct LambertVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(2) worldPosition: vec3<f32>, // Safely placed at location(2) to avoid framework auto-injected UV clashes
    @location(3) worldNormal: vec3<f32>,   // Safely placed at location(3) to pass vertex normals down
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.lambert.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.lambert.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> LambertVertexOutput {
    var output: LambertVertexOutput;
    var position = input.position;
    var normal = input.normal;
    var vertexColor = input.color;

    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    let worldPosition4 = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition4.xyz;

    // Transform and pass normal down to the fragment shader
    output.worldNormal = normalize((uniforms.modelMatrix * vec4<f32>(normal, 0.0)).xyz);
    
    let viewPosition = uniforms.scene.viewMatrix * worldPosition4;
    output.position = uniforms.scene.projectionMatrix * viewPosition;

    // Apply material base tint and vertex color
    output.color = uniforms.baseColor.rgb * vertexColor;
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.lambert.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct LambertFragmentInput {
    @location(0) color: vec3<f32>,
    @location(2) worldPosition: vec3<f32>, // Matched location(2) shift
    @location(3) worldNormal: vec3<f32>,   // Matched location(3) shift
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.lambert.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.lights>
#include <common.fog>
#include <common.color>
#include <common.clipping>
#include <common.flat_shading> // Injects your clean evaluateNormal() function!
#include <material.lambert.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: LambertFragmentInput) -> @location(0) vec4<f32> {
    evaluateClippingPlanes(input.worldPosition);
    var color = input.color;
    var alphaOverride = uniforms.baseColor.a;
    
    // 1. Evaluate normal using your shared flat shading chunk function
    // Dynamically chooses smooth or sharp facets depending on uniforms.pbrParams.z
    let N = evaluateNormal(input.worldNormal, input.worldPosition); 
    let V = normalize(uniforms.scene.cameraPosition.xyz - input.worldPosition);

    {{FRAGMENT_INIT_EXTRA}}
    {{FRAGMENT_EXTRA}}

    // 2. Convert incoming albedo color to linear space for accurate multi-light equations
    let linearAlbedo = sRGBTransferEETF(vec4<f32>(color, 1.0)).rgb;

    // 3. Compute lighting using your 6-argument shared chunk
    // We pass 0.0 for shininess and a blank vec3 for specular color since Lambert is fully matte!
    var finalColor = calculateDynamicLighting(N, V, input.worldPosition, linearAlbedo, 0.0, vec3<f32>(0.0));

    // 4. Apply the environmental distance fog factor
    finalColor = applyFog(finalColor, input.worldPosition);

    var finalRGBA = vec4<f32>(finalColor, alphaOverride);
    
    // 5. Transform from working linear room back into the requested Output Color Space
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}
    ''',
  ),
];
