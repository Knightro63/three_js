import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const List<ShaderChunk> customShader = [
  ShaderChunk(
    name: 'material.customShader.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
    struct VertexInput {
        @location(0) position: vec3<f32>,
        @location(1) color: vec3<f32>,
        {{VERTEX_INPUT_EXTRA}}
    }

    struct CustomVertexOutput {
        @builtin(position) position: vec4<f32>,
        @location(0) color: vec3<f32>,
        {{VERTEX_OUTPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.customShader.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
    #include <common.uniforms> // Injected for ShaderMaterial, omitted for RawShaderMaterial
    #include <material.customShader.vertex.input>

    @vertex
    fn vs_main(input: VertexInput) -> CustomVertexOutput {
        var output: CustomVertexOutput;
        var position = input.position;
        var vertexColor = input.color;
        
        // User custom code strings block injected seamlessly right here
        {{VERTEX_ASSIGN_EXTRA}}

        let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
        output.position = uniforms.scene.projectionMatrix * uniforms.scene.viewMatrix * worldPosition;
        output.color = uniforms.baseColor.rgb * vertexColor;
        return output;
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.customShader.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
    struct CustomFragmentInput {
        @location(0) color: vec3<f32>,
        {{FRAGMENT_INPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.customShader.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
    #include <common.uniforms>
    #include <common.clipping>
    #include <material.customShader.fragment.input>
    {{FRAGMENT_BINDINGS}}

    @fragment
    fn fs_main(input: CustomFragmentInput) -> @location(0) vec4<f32> {
        evaluateClippingPlanes(input.worldPosition);
        var color = input.color;
        {{FRAGMENT_INIT_EXTRA}}
        
        // User custom shading math lines run right here
        {{FRAGMENT_EXTRA}}

        return vec4<f32>(color, uniforms.baseColor.a);
    }
    ''',
  )
];