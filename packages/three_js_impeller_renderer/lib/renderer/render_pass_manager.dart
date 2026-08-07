import 'dart:core';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:vector_math/vector_math.dart' as vmath;
import 'buffer_manager.dart';
import 'frame_attachments.dart'; // Adjust based on your exact gpu library paths

/// Gpu render pass manager implementation.
///
/// Records drawing commands using GpuRenderPassEncoder.
class RenderPassManager {
  // Track render pass state securely without late initialization flags
  gpu.RenderPass? _renderpass;
  bool _renderPassActive = false;
  bool _pipelineBound = false;

  /// Set to true to enable descriptor logging for this frame's render pass
  bool enableDiagnostics = false;

  /// Get the internal GpuRenderPassEncoder for legacy rendering code.
  /// This is a temporary method to support the transition from direct Gpu API usage
  /// to the RenderPassManager abstraction.
  gpu.RenderPass get getPassEncoder => _renderpass!;

  FramebufferAttachments? _oldframebuffer;
  gpu.RenderTarget? _renderTarget;

  /// Begin render pass with clear color context states.
  void beginRenderPass(gpu.CommandBuffer commandBuffer, Color clearColor, FramebufferAttachments framebuffer) {
    if(framebuffer == _oldframebuffer){
      _renderpass = commandBuffer.createRenderPass(this._renderTarget!);
      return;
    }

    if (_renderPassActive) {
      throw RenderPassException("Render pass already active. Call endRenderPass() first.");
    }

    //try {
      final gpu.Texture textureView;
      final gpu.Texture? depthView;
      final gpu.Texture? resolveView;

      textureView = framebuffer.colorView;
      depthView = framebuffer.depthView;
      resolveView = framebuffer.resolveView; 

      // Replaces programmatic js("{}") assemblies with a clean, strongly-typed gpu declarative object
      final colorAttachment = gpu.ColorAttachment(
        texture: textureView,
        loadAction: gpu.LoadAction.clear,
        resolveTexture: resolveView,
        storeAction: resolveView != null ? gpu.StoreAction.multisampleResolve : gpu.StoreAction.store, // Discard 4x view memory if resolved
        clearValue: vmath.Vector4(
          clearColor.red,
          clearColor.green,
          clearColor.blue,
          clearColor.alpha,
        ),
      );

      gpu.DepthStencilAttachment? depthStencilAttachment;
      if (depthView != null) {
        depthStencilAttachment = gpu.DepthStencilAttachment(
          texture: depthView,
          depthClearValue: 1.0,
          depthLoadAction: gpu.LoadAction.clear,
          depthStoreAction: resolveView == null ? gpu.StoreAction.dontCare : gpu.StoreAction.dontCare,
        );
      }

      // Diagnostics logging window block
      if (enableDiagnostics) {
        console.info(
          "PASS-DESC: textureView type=${textureView.runtimeType}, "
          "clear=[${clearColor.red}, ${clearColor.green}, ${clearColor.blue}, ${clearColor.alpha}], "
          "depthView=${depthView != null}, "
          "colorAttachments.length=1"
        );
      }

      _renderTarget = gpu.RenderTarget.singleColor(
        colorAttachment,
        depthStencilAttachment:depthStencilAttachment
      );

      // Spun up the active render command encoder context lane
      _renderpass = commandBuffer.createRenderPass(_renderTarget!);
      
      if (_renderpass == null) {
        throw RenderPassException("Failed to begin render pass");
      }

      if (enableDiagnostics) {
        console.info("PASS-DESC: passEncoder=${_renderpass.runtimeType}, active=true");
      }

      _renderPassActive = true;
      _pipelineBound = false;
      _oldframebuffer = framebuffer;
    // } on RenderPassException {
    //   rethrow;
    // } catch (e) {
    //   throw RenderPassException("Failed to begin render pass: ${e.toString()}");
    // }
  }

  /// Bind graphics pipeline context state variables.
  void bindPipeline(PipelineHandle pipeline) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }

    try {
      _renderpass!.bindPipeline(pipeline.handle);
      _pipelineBound = true;
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError("Failed to bind pipeline: ${e.toString()}");
    }
  }

  /// Bind vertex buffer into an active tracking layout entry location slot index.
  void bindVertexBuffer(BufferHandle buffer, int vertexCount) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }
    if (!buffer.isValid()) {
      throw InvalidBufferException("Vertex buffer handle is invalid");
    }

    try {
      final gpuBuffer = buffer.view;
      _renderpass!.bindVertexBuffer(gpuBuffer, vertexCount);// .setVertexBuffer(slot, gpuBuffer);
    } on InvalidBufferException {
      rethrow;
    } catch (e) {
      throw InvalidBufferException("Failed to bind vertex buffer: ${e.toString()}");
    }
  }

  /// Bind index buffer using specialized 16-bit or 32-bit layout properties configurations.
  void bindIndexBuffer(BufferHandle buffer) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }
    if (!buffer.isValid()) {
      throw InvalidBufferException("Index buffer handle is invalid");
    }

    final int indexSizeInBytes = buffer.sizeBytes;

    if (indexSizeInBytes != 2 && indexSizeInBytes != 4) {
      throw ArgumentError("Index size must be 2 or 4 bytes, got $indexSizeInBytes");
    }

    try {
      final gpuBuffer = buffer.view;
      _renderpass!.bindIndexBuffer(gpuBuffer, buffer.format, buffer.length);
    } on InvalidBufferException {
      rethrow;
    } catch (e) {
      throw InvalidBufferException("Failed to bind index buffer: ${e.toString()}");
    }
  }

  /// Bind uniform buffer to group and binding layouts.
  void bindUniformBuffer(BufferHandle buffer) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }
    if (!buffer.isValid()) {
      throw InvalidBufferException("Uniform buffer handle is invalid");
    }

    try {
      // Note: Uniform buffer binding requires GPUBindGroup creation with bind group layout.
      // This is deferred to full pipeline implementation where bind group layouts are defined.
      // For Feature 020 core implementation, uniform buffers are created and managed,
      // but binding requires integration with the full rendering pipeline (GpuRenderer).
    } on InvalidBufferException {
      rethrow;
    } catch (e) {
      throw InvalidBufferException("Failed to bind uniform buffer: ${e.toString()}");
    }
  }

  /// Draw indexed geometric primitives.
  void draw() {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }
    if (!_pipelineBound) {
      throw StateError("No pipeline bound. Call bindPipeline() first.");
    }

    try {
      _renderpass!.draw();
    } catch (e) {
      throw StateError("Failed to draw indexed: ${e.toString()}");
    }
  }

  /// End render pass execution lane tracking loops.
  void endRenderPass() {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }

    try {
      //_renderpass!.draw();
      _renderPassActive = false;
      _pipelineBound = false;
      _renderpass = null;
    } catch (e) {
      throw StateError("Failed to end render pass: ${e.toString()}");
    }
  }
}

class PipelineHandle {
  final gpu.RenderPipeline handle;
  const PipelineHandle(this.handle);
}

class RenderPassException implements Exception {
  final String message;
  const RenderPassException(this.message);
  @override
  String toString() => "RenderPassException: $message";
}
