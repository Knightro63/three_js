import 'package:gpux/gpux.dart';
import 'package:three_js_core/three_js_core.dart'; // Adjust based on your exact gpux library path

/// T033: Shader Loader for WebGPU
/// Feature: 019-we-should-not
///
/// Helper function to load WGSL shaders for WebGPU.
/// For MVP, the shader is embedded directly as a multiline string raw asset.
String loadBasicShader() {
  // T033: Embedded basic.wgsl shader.
  // Using Dart's raw multiline string notation (r''') to safely preserve symbols without escape sequences.
  return r'''
    // Basic WGSL Shader (T031)
    // Compatible with WebGPU (native) and Vulkan (via SPIR-V compilation)
    
    // Uniform buffer for transformation matrices
    struct Uniforms {
        modelViewProjection: mat4x4<f32>,
    };
    @group(0) @binding(0) var<uniform> uniforms: Uniforms;

    // Vertex shader input
    struct VertexInput {
        @location(0) position: vec3<f32>,
        @location(1) color: vec3<f32>,
    };

    // Vertex shader output / Fragment shader input
    struct VertexOutput {
        @builtin(position) position: vec4<f32>,
        @location(0) color: vec3<f32>,
    };

    // Vertex shader
    @vertex
    fn vs_main(input: VertexInput) -> VertexOutput {
        var output: VertexOutput;
        // Transform vertex position by MVP matrix
        output.position = uniforms.modelViewProjection * vec4<f32>(input.position, 1.0);
        // Pass color to fragment shader
        output.color = input.color;
        return output;
    }

    // Fragment shader
    @fragment
    fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
        // Output per-vertex color with full opacity
        return vec4<f32>(input.color, 1.0);
    }
  ''';
}

/// Create basic WebGPU pipeline with the embedded shader module.
///
/// @param device The active [GpuDevice] instance from your gpux backend.
/// @return [GpuRenderPipeline] or null on a creation failure.
GpuRenderPipeline? createBasicPipeline(GpuDevice device) {
  try {
    final shaderCode = loadBasicShader();

    // 1. Compile the string code into a structured hardware shader module
    final shaderModule = device.createShaderModule(
      shaderCode,
    );

    // 2. Build the strict Render Pipeline descriptor block instead of using dynamic JS literals
    final pipelineDescriptor = GpuRenderPipelineDescriptor(
      layout: null,
      vertexModule: shaderModule,
      vertexEntryPoint: 'vs_main',
      // If your geometries pass interlocked stride blocks, specify layouts here:
      vertexBuffers: [], 
      fragmentModule: shaderModule,
      fragmentEntryPoint: 'fs_main',
      colorTargets: [
        GpuColorTargetState(format: GpuTextureFormat.bgra8Unorm),
      ],
      primitiveTopology: GpuPrimitiveTopology.triangleList, // Maps to 'triangle-list'
    );

    // 3. Request the backend engine to build the pipeline
    return device.createRenderPipeline(pipelineDescriptor);
  } catch (e) {
    console.error("ERROR: Failed to create basic pipeline: ${e.toString()}");
    return null;
  }
}
