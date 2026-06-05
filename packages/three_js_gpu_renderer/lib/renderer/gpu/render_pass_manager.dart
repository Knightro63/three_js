import 'dart:core';
import 'package:gpux/gpux.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'buffer_manager.dart';
import 'frame_attachments.dart'; // Adjust based on your exact gpux library paths

/// Gpu render pass manager implementation.
///
/// Records drawing commands using GpuRenderPassEncoder.
class GpuRenderPassManager implements RenderPassManager {
  final gpux.GpuCommandEncoder commandEncoder;

  // Track render pass state securely without late initialization flags
  gpux.GpuRenderPassEncoder? _passEncoder;
  bool _renderPassActive = false;
  bool _pipelineBound = false;

  /// Set to true to enable descriptor logging for this frame's render pass
  bool enableDiagnostics = false;

  GpuRenderPassManager(this.commandEncoder);

  /// Get the internal GpuRenderPassEncoder for legacy rendering code.
  /// This is a temporary method to support the transition from direct Gpu API usage
  /// to the RenderPassManager abstraction.
  gpux.GpuRenderPassEncoder? getPassEncoder() => _passEncoder;

  /// Begin render pass with clear color context states.
  @override
  void beginRenderPass({required Color clearColor, required FramebufferHandle framebuffer}) {
    if (_renderPassActive) {
      throw RenderPassException("Render pass already active. Call endRenderPass() first.");
    }

    try {
      final handle = framebuffer.handle;
      if (handle == null) {
        throw ArgumentError("framebuffer.handle must not be null");
      }

      final gpux.GpuTextureView colorView;
      final gpux.GpuTextureView? depthView;
      final gpux.GpuTextureView? resolveView;

      if (handle is GpuFramebufferAttachments) {
        colorView = handle.colorView;
        depthView = handle.depthView;
        resolveView = handle.resolveView; 
      } else if (handle is gpux.GpuTextureView) {
        colorView = handle;
        depthView = null;
        resolveView = null;
      } else {
        throw ArgumentError("framebuffer.handle must be GpuTextureView or GpuFramebufferAttachments");
      }

      // Replaces programmatic js("{}") assemblies with a clean, strongly-typed gpux declarative object
      final colorAttachment = gpux.GpuColorAttachment(
        view: colorView,
        loadOp: gpux.GpuLoadOp.clear,
        resolveTarget: resolveView,
        storeOp: resolveView != null ? gpux.GpuStoreOp.discard : gpux.GpuStoreOp.store, // Discard 4x view memory if resolved
        clearValue: gpux.GpuColor(
          clearColor.red,
          clearColor.green,
          clearColor.blue,
          clearColor.alpha,
        ),
      );

      gpux.GpuDepthStencilAttachment? depthStencilAttachment;
      if (depthView != null) {
        depthStencilAttachment = gpux.GpuDepthStencilAttachment(
          view: depthView,
          depthClearValue: 1.0,
          depthLoadOp: gpux.GpuLoadOp.clear,
          depthStoreOp: resolveView != null ? gpux.GpuStoreOp.discard : gpux.GpuStoreOp.store,
        );
      }

      // Diagnostics logging window block
      if (enableDiagnostics) {
        console.info(
          "PASS-DESC: colorView type=${colorView.runtimeType}, "
          "clear=[${clearColor.red}, ${clearColor.green}, ${clearColor.blue}, ${clearColor.alpha}], "
          "depthView=${depthView != null}, "
          "colorAttachments.length=1"
        );
      }

      // Spun up the active render command encoder context lane
      _passEncoder = commandEncoder.beginRenderPass(
        colorAttachments: [colorAttachment], 
        depthStencilAttachment: depthStencilAttachment
      );
      
      if (_passEncoder == null) {
        throw RenderPassException("Failed to begin render pass");
      }

      if (enableDiagnostics) {
        console.info("PASS-DESC: passEncoder=${_passEncoder.runtimeType}, active=true");
      }

      _renderPassActive = true;
      _pipelineBound = false;
    } on RenderPassException {
      rethrow;
    } catch (e) {
      throw RenderPassException("Failed to begin render pass: ${e.toString()}");
    }
  }

  /// Bind graphics pipeline context state variables.
  @override
  void bindPipeline(PipelineHandle pipeline) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }

    try {
      final renderPipeline = pipeline.handle;
      if (renderPipeline is! gpux.GpuRenderPipeline) {
        throw ArgumentError("pipeline.handle must be GpuRenderPipeline");
      }

      _passEncoder!.setPipeline(renderPipeline);
      _pipelineBound = true;
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError("Failed to bind pipeline: ${e.toString()}");
    }
  }

  /// Bind vertex buffer into an active tracking layout entry location slot index.
  @override
  void bindVertexBuffer(BufferHandle buffer, int slot) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }
    if (!buffer.isValid()) {
      throw InvalidBufferException("Vertex buffer handle is invalid");
    }

    try {
      final gpuBuffer = buffer.handle;
      if (gpuBuffer is! gpux.GpuBuffer) {
        throw InvalidBufferException("Buffer handle is null or invalid");
      }

      _passEncoder!.setVertexBuffer(slot, gpuBuffer);
    } on InvalidBufferException {
      rethrow;
    } catch (e) {
      throw InvalidBufferException("Failed to bind vertex buffer: ${e.toString()}");
    }
  }

  /// Bind index buffer using specialized 16-bit or 32-bit layout properties configurations.
  @override
  void bindIndexBuffer(BufferHandle buffer, int indexSizeInBytes) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }
    if (!buffer.isValid()) {
      throw InvalidBufferException("Index buffer handle is invalid");
    }
    
    if (indexSizeInBytes != 2 && indexSizeInBytes != 4) {
      throw ArgumentError("Index size must be 2 or 4 bytes, got $indexSizeInBytes");
    }

    try {
      final gpuBuffer = buffer.handle;
      if (gpuBuffer is! gpux.GpuBuffer) {
        throw InvalidBufferException("Buffer handle is null or invalid");
      }

      final format = indexSizeInBytes == 2 ? gpux.GpuIndexFormat.uint16 : gpux.GpuIndexFormat.uint32;
      _passEncoder!.setIndexBuffer(gpuBuffer, format);
    } on InvalidBufferException {
      rethrow;
    } catch (e) {
      throw InvalidBufferException("Failed to bind index buffer: ${e.toString()}");
    }
  }

  /// Bind uniform buffer to group and binding layouts.
  @override
  void bindUniformBuffer(BufferHandle buffer, int group, int binding) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }
    if (!buffer.isValid()) {
      throw InvalidBufferException("Uniform buffer handle is invalid");
    }

    try {
      final gpuBuffer = buffer.handle;
      if (gpuBuffer is! gpux.GpuBuffer) {
        throw InvalidBufferException("Buffer handle is null or invalid");
      }
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
  void drawIndexed(int indexCount, int firstIndex, int instanceCount) {
    if (!_renderPassActive) {
      throw StateError("No active render pass. Call beginRenderPass() first.");
    }
    if (!_pipelineBound) {
      throw StateError("No pipeline bound. Call bindPipeline() first.");
    }

    try {
      _passEncoder!.drawIndexed(
        indexCount: indexCount,
        instanceCount: instanceCount,
        firstIndex: firstIndex,
        baseVertex: 0,
        firstInstance: 0,
      );
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
      _passEncoder!.end();
      _renderPassActive = false;
      _pipelineBound = false;
      _passEncoder = null;
    } catch (e) {
      throw StateError("Failed to end render pass: ${e.toString()}");
    }
  }
}

// ==========================================
// INTERFACE CONTRACT PATTERN DEPENDENCIES
// ==========================================

abstract class RenderPassManager {
  void beginRenderPass({required Color clearColor, required FramebufferHandle framebuffer});
  void bindPipeline(PipelineHandle pipeline);
  void bindVertexBuffer(BufferHandle buffer, int slot);
  void bindIndexBuffer(BufferHandle buffer, int indexSizeInBytes);
  void bindUniformBuffer(BufferHandle buffer, int group, int binding);
  void drawIndexed(int indexCount, int firstIndex, int instanceCount);
  void endRenderPass();
}

class FramebufferHandle {
  final dynamic handle;
  const FramebufferHandle(this.handle);
}

class PipelineHandle {
  final dynamic handle;
  const PipelineHandle(this.handle);
}

class RenderPassException implements Exception {
  final String message;
  const RenderPassException(this.message);
  @override
  String toString() => "RenderPassException: $message";
}
