import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart'; 

const List<ShaderChunk> distance = [ 
  ShaderChunk(
    name: 'material.distance.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
    struct VertexInput {
        @location(0) position: vec3<f32>,
        @location(1) normal: vec3<f32>,
        @location(2) color: vec3<f32>,
        {{VERTEX_INPUT_EXTRA}}
    }

    struct DistanceVertexOutput {
        @builtin(position) position: vec4<f32>,
        @location(0) color: vec3<f32>,
        @location(1) worldPosition: vec3<f32>,
        {{VERTEX_OUTPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.distance.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
    #include <common.uniforms> 
    #include <material.distance.vertex.input>

    @vertex
    fn vs_main(input: VertexInput) -> DistanceVertexOutput {
        var output: DistanceVertexOutput;
        var position = input.position;
        var normal = input.normal;
        var vertexColor = input.color;

        // Direct safety initialization check
        if (dot(vertexColor, vertexColor) <= 0.0) { 
            vertexColor = vec3<f32>(1.0); 
        }

        {{VERTEX_ASSIGN_EXTRA}}

        let worldPosition4 = uniforms.modelMatrix * vec4<f32>(position, 1.0);
        output.worldPosition = worldPosition4.xyz;
        
        let viewPosition = uniforms.scene.viewMatrix * worldPosition4;
        output.position = uniforms.scene.projectionMatrix * viewPosition;
        
        output.color = uniforms.baseColor.rgb * vertexColor;
        return output;
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.distance.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
    struct DistanceFragmentInput {
        @location(0) color: vec3<f32>,
        @location(1) worldPosition: vec3<f32>,
        {{FRAGMENT_INPUT_EXTRA}}
    }
    ''',
  ),
  ShaderChunk(
    name: 'material.distance.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
    #include <common.uniforms> 
    #include <material.distance.fragment.input>
    #include <common.clipping>

    {{FRAGMENT_BINDINGS}}

    @fragment
    fn fs_main(input: DistanceFragmentInput) -> @location(0) vec4<f32> {
        evaluateClippingPlanes(input.worldPosition);
        var color = input.color;

        {{FRAGMENT_INIT_EXTRA}}

        // Calculate absolute Euclidean distance from camera position to current fragment
        let distanceToCamera = length(input.worldPosition - uniforms.scene.cameraPosition.xyz); 

        // DYNAMIC UPGRADE: Instead of a hardcoded 50.0 radius (which causes 800-unit camera 
        // loops to blow out into flat white), map the normalization windows to your Fog bounds!
        let near = uniforms.scene.fogParams.x;
        var far = uniforms.scene.fogParams.y;
        
        // Safety check fallback logic in case your scene doesn't define standard fog parameters
        if (far <= near) {
            far = 2000.0; 
        }

        // Three.js Parity Normalization: Linearly scales depth into an accurate [0.0, 1.0] gradient range
        let normalizedDistance = clamp((distanceToCamera - near) / (far - near), 0.0, 1.0);

        {{FRAGMENT_EXTRA}}

        // Outputs a beautifully calibrated grayscale map reflecting Euclidean spacing tracking
        return vec4<f32>(vec3<f32>(normalizedDistance), uniforms.baseColor.a); 
    }
    ''',
  ),
];
