import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> matcap = [ 
  ShaderChunk(
    name: 'material.matcap.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}

struct MatcapVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(2) worldNormal: vec3<f32>,    // Safely placed at location(2) to clear room for framework auto-injected UVs
    @location(3) worldPosition: vec3<f32>, // Passes world coordinates down to support derivative calculations and fog
    {{VERTEX_OUTPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.matcap.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms> 
#include <material.matcap.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> MatcapVertexOutput {
    var output: MatcapVertexOutput;
    var position = input.position;
    var normal = input.normal;
    var vertexColor = input.color;

    if (dot(vertexColor, vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition.xyz;
    
    output.position = uniforms.scene.projectionMatrix * uniforms.scene.viewMatrix * worldPosition;
    
    // Pass raw model-space normal down to fragment stage for precise per-pixel evaluation
    output.worldNormal = normalize((uniforms.modelMatrix * vec4<f32>(normal, 0.0)).xyz);
    
    output.color = uniforms.baseColor.rgb * vertexColor;
    return output;
}
    ''',
  ),
  ShaderChunk(
    name: 'material.matcap.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct MatcapFragmentInput {
    @location(0) color: vec3<f32>,
    @location(2) worldNormal: vec3<f32>,   // Received safely on slot 2
    @location(3) worldPosition: vec3<f32>, // Received safely on slot 3
    {{FRAGMENT_INPUT_EXTRA}}
}
    ''',
  ),
  ShaderChunk(
    name: 'material.matcap.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms> 
#include <common.fog>
#include <common.color>
#include <common.clipping>
#include <common.flat_shading> // Injects your clean evaluateNormal() function!
#include <material.matcap.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: MatcapFragmentInput) -> @location(0) vec4<f32> {
    evaluateClippingPlanes(input.worldPosition);
    var color = input.color; 
    var matcapColor = vec3<f32>(1.0); // Default fallback if no matcap texture is attached
    
    // 1. Evaluate normal using your shared flat shading chunk function
    // Dynamically posterizes the surface using partial derivatives if uniforms.pbrParams.z is active
    let N = evaluateNormal(input.worldNormal, input.worldPosition);
    
    // 2. Compute the 3x3 normal rotation matrix in the fragment stage
    let modelViewMatrix = uniforms.scene.viewMatrix * uniforms.modelMatrix;
    let normalMatrix = mat3x3<f32>(
        modelViewMatrix[0].xyz,
        modelViewMatrix[1].xyz,
        modelViewMatrix[2].xyz
    );
    
    // Transform our finalized normal into View-Space (Camera Space)
    let viewNormal = normalize(normalMatrix * N);
    
    // 3. Calculate matcap sphere mapping texture coordinates out of the view normal
    var matcapUv = viewNormal.xy * 0.5 + vec2<f32>(0.5);
    matcapUv.y = 1.0 - matcapUv.y; // Flip Y to conform to WebGL texture standards

    {{FRAGMENT_INIT_EXTRA}} 
    {{FRAGMENT_EXTRA}} 

    // Combine base material tint with the sampled material capture map layer
    var finalColor = color * matcapColor;

    // 4. Apply dynamic environmental distance fog factors
    finalColor = applyFog(finalColor, input.worldPosition);

    var finalRGBA = vec4<f32>(finalColor, uniforms.baseColor.a);
    
    // 5. Run central color space encoding rules (sRGB / Display P3)
    finalRGBA = applyColor(finalRGBA);

    return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
}
    ''',
  ),
];
