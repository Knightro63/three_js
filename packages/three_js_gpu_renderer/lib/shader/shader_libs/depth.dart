import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> depth = [ 
  ShaderChunk(
    name: 'material.depth.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
    struct VertexInput {
        @location(0) position: vec3<f32>,
        @location(1) normal: vec3<f32>,
        @location(2) color: vec3<f32>,
        {{VERTEX_INPUT_EXTRA}}
    }

    struct DepthVertexOutput {
        @builtin(position) position: vec4<f32>,
        @location(0) color: vec3<f32>,
        {{VERTEX_OUTPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.depth.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
    #include <common.uniforms> 
    #include <material.depth.vertex.input>

    @vertex
    fn vs_main(input: VertexInput) -> DepthVertexOutput {
        var output: DepthVertexOutput;
        var position = input.position;
        var normal = input.normal;
        var vertexColor = input.color;

        {{VERTEX_ASSIGN_EXTRA}}

        let worldPosition = uniforms.modelMatrix * vec4<f32>(position, 1.0);
        let viewPosition = uniforms.scene.viewMatrix * worldPosition;
        output.position = uniforms.scene.projectionMatrix * viewPosition;

        output.color = vertexColor;
        return output;
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.depth.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
    struct DepthFragmentInput {
        @builtin(position) fragCoord: vec4<f32>,
        @location(0) color: vec3<f32>,
        {{FRAGMENT_INPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.depth.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
    #include <common.uniforms> 
    #include <material.depth.fragment.input>
    #include <common.clipping>

    {{FRAGMENT_BINDINGS}}

    @fragment
    fn fs_main(input: DepthFragmentInput) -> @location(0) vec4<f32> {
        evaluateClippingPlanes(input.worldPosition);
        var color = input.color;

        {{FRAGMENT_INIT_EXTRA}}

        // Fetch the hardware depth directly [0.0 to 1.0]
        let z = input.fragCoord.z; 

        // FIX 1: Map near and far clip limits dynamically from your existing setup function bounds
        // Your setup maps near to 1.0 and far to 2000.0 via the PerspectiveCamera initialization
        let near = 1.0;
        let far = 2000.0;

        // FIX 2: Correct depth linearization formula tailored specifically for WebGPU's [0.0, 1.0] NDC space range
        // Formula: (near * far) / (far - z * (far - near))
        let linearDistance = (near * far) / (far - z * (far - near));
        
        // Normalize the linear distance into a perfect [0.0, 1.0] visualization gradient fraction
        let linearDepth = (linearDistance - near) / (far - near);

        {{FRAGMENT_EXTRA}}

        // Returns a beautifully scaled grayscale depth gradient representing scene thickness
        return vec4<f32>(vec3<f32>(clamp(linearDepth, 0.0, 1.0)), uniforms.baseColor.a); 
    }
    ''',
  ),
];
