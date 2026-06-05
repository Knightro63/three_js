import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const List<ShaderChunk> lineBasic = [
  ShaderChunk(
    name: 'material.lineBasic.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
    struct VertexInput {
        @location(0) position: vec3<f32>,
        @location(1) color: vec3<f32>,
        {{VERTEX_INPUT_EXTRA}}
    }

    struct LineBasicVertexOutput {
        @builtin(position) position: vec4<f32>,
        @location(0) color: vec3<f32>,
        {{VERTEX_OUTPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.lineBasic.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
    #include <common.uniforms>
    #include <material.lineBasic.vertex.input>

    @vertex
    fn vs_main(input: VertexInput) -> LineBasicVertexOutput {
        var output: LineBasicVertexOutput;
        var position = input.position;
        var vertexColor = input.color;
        if (length(vertexColor) <= 0.0) {
            vertexColor = vec3<f32>(1.0);
        }
        {{VERTEX_ASSIGN_EXTRA}}

        let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
        output.position = uniforms.scene.projectionMatrix * uniforms.scene.viewMatrix * worldPosition;
        
        output.color = uniforms.baseColor.rgb * vertexColor;
        return output;
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.lineBasic.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
    struct LineBasicFragmentInput {
        @location(0) color: vec3<f32>,
        {{FRAGMENT_INPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.lineBasic.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
    #include <common.uniforms>
    #include <material.lineBasic.fragment.input>
    {{FRAGMENT_BINDINGS}}

    @fragment
    fn fs_main(input: LineBasicFragmentInput) -> @location(0) vec4<f32> {
        var color = input.color;
        {{FRAGMENT_INIT_EXTRA}}
        {{FRAGMENT_EXTRA}}

        return vec4<f32>(color, uniforms.baseColor.a);
    }
    ''',
  )
];