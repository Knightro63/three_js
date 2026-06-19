import 'dart:core';
import 'package:flutter_gpu/gpu.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:vector_math/vector_math.dart' as vmath;
import 'buffer_manager.dart';
import 'frame_attachments.dart'; // Adjust based on your exact gpux library paths

/// Gpu render pass manager implementation.
///
/// Records drawing commands using GpuRenderPassEncoder.
class GpuRenderPassManager implements RenderPassManager {
  // Track render pass state securely without late initialization flags
  gpux.RenderPass? _renderpass;
  bool _renderPassActive = false;
  bool _pipelineBound = false;

  /// Set to true to enable descriptor logging for this frame's render pass
  bool enableDiagnostics = false;

  /// Get the internal GpuRenderPassEncoder for legacy rendering code.
  /// This is a temporary method to support the transition from direct Gpu API usage
  /// to the RenderPassManager abstraction.
  gpux.RenderPass get getPassEncoder => _renderpass!;

  GpuFramebufferAttachments? _oldframebuffer;
  gpux.RenderTarget? _renderTarget;

  /// Begin render pass with clear color context states.
  @override
  void beginRenderPass(gpux.CommandBuffer commandBuffer, Color clearColor, GpuFramebufferAttachments framebuffer) {
    if(framebuffer == _oldframebuffer){
      _renderpass = commandBuffer.createRenderPass(this._renderTarget!);
      return;
    }

    if (_renderPassActive) {
      throw RenderPassException("Render pass already active. Call endRenderPass() first.");
    }

    //try {
      final gpux.Texture textureView;
      final gpux.Texture? depthView;
      final gpux.Texture? resolveView;

      textureView = framebuffer.colorView;
      depthView = framebuffer.depthView;
      resolveView = framebuffer.resolveView; 

      // Replaces programmatic js("{}") assemblies with a clean, strongly-typed gpux declarative object
      final colorAttachment = gpux.ColorAttachment(
        texture: textureView,
        loadAction: gpux.LoadAction.clear,
        resolveTexture: resolveView,
        storeAction: resolveView != null ? gpux.StoreAction.multisampleResolve : gpux.StoreAction.store, // Discard 4x view memory if resolved
        clearValue: vmath.Vector4(
          clearColor.red,
          clearColor.green,
          clearColor.blue,
          clearColor.alpha,
        ),
      );

      gpux.DepthStencilAttachment? depthStencilAttachment;
      if (depthView != null) {
        depthStencilAttachment = gpux.DepthStencilAttachment(
          texture: depthView,
          depthClearValue: 1.0,
          depthLoadAction: gpux.LoadAction.clear,
          depthStoreAction: resolveView == null ? gpux.StoreAction.dontCare : gpux.StoreAction.dontCare,
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

      _renderTarget = gpux.RenderTarget.singleColor(
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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

// ==========================================
// INTERFACE CONTRACT PATTERN DEPENDENCIES
// ==========================================

abstract class RenderPassManager {
  void beginRenderPass(gpux.CommandBuffer commandBuffer ,Color clearColor, GpuFramebufferAttachments framebuffer);
  void bindPipeline(PipelineHandle pipeline);
  void bindVertexBuffer(BufferHandle buffer, int slot);
  void bindIndexBuffer(BufferHandle buffer);
  void bindUniformBuffer(BufferHandle buffer);
  //void drawIndexed(int indexCount, int firstIndex, int instanceCount);
  void draw();
  void endRenderPass();
}

class PipelineHandle {
  final gpux.RenderPipeline handle;
  const PipelineHandle(this.handle);
}

class RenderPassException implements Exception {
  final String message;
  const RenderPassException(this.message);
  @override
  String toString() => "RenderPassException: $message";
}
