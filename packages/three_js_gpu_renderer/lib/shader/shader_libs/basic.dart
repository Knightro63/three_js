import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const List<ShaderChunk> basic = [ 
  ShaderChunk(
    name: 'material.basic.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
    struct VertexInput {
        @location(0) position: vec3<f32>,
        @location(1) normal: vec3<f32>,
        @location(2) color: vec3<f32>,
        {{VERTEX_INPUT_EXTRA}}
    }

    struct BasicVertexOutput {
        @builtin(position) position: vec4<f32>,
        @location(0) color: vec3<f32>,
        @location(1) worldPosition: vec3<f32>,
        {{VERTEX_OUTPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.basic.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
    #include <common.uniforms> 
    #include <material.basic.vertex.input>

    @vertex
    fn vs_main(input: VertexInput) -> BasicVertexOutput {
        var output: BasicVertexOutput;
        var position = input.position;
        var normal = input.normal;
        var vertexColor = input.color;

        {{VERTEX_ASSIGN_EXTRA}}

        let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
        let viewPosition = uniforms.scene.viewMatrix * worldPosition;
        
        output.position = uniforms.scene.projectionMatrix * viewPosition;
        
        // FIX 1: Explicitly pass the world position to the fragment stage for fog tracking
        output.worldPosition = worldPosition.xyz;

        let materialColor = uniforms.baseColor.rgb;
        output.color = materialColor * vertexColor;
        
        return output;
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.basic.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
    struct BasicFragmentInput {
        @location(0) color: vec3<f32>,
        @location(1) worldPosition: vec3<f32>,
        {{FRAGMENT_INPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.basic.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
    #include <common.uniforms> 
    #include <common.fog> 
    #include <common.color>
    #include <common.clipping>
    #include <material.basic.fragment.input>

    {{FRAGMENT_BINDINGS}}

    @fragment
    fn fs_main(input: BasicFragmentInput) -> @location(0) vec4<f32> {
        evaluateClippingPlanes(input.worldPosition);
        var color = input.color;
        var alphaOverride = uniforms.baseColor.a;

        {{FRAGMENT_INIT_EXTRA}}
        {{FRAGMENT_EXTRA}}

        // Apply the world-distance fog
        var finalColor = applyFog(color, input.worldPosition);
        
        // Assemble into vec4 to support color space transformation updates
        var finalRGBA = vec4<f32>(finalColor, alphaOverride);
        
        // FIX 2: Apply color space encoding rules (sRGB, Display P3, etc.)
        finalRGBA = applyColor(finalRGBA);

        return vec4<f32>(clamp(finalRGBA.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), finalRGBA.a);
    }
    ''',
  ),
];
