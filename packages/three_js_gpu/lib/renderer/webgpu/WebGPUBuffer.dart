import 'dart:typed_data';
import 'package:gpux/gpux.dart';
import 'package:three_js_core/three_js_core.dart'; // Adjust based on your exact gpux library path

/// WebGPU buffer implementation.
/// T030: GPU buffer management for vertices, indices, and uniforms.
class WebGPUBuffer {
  final GpuDevice device;
  final BufferDescriptor descriptor;

  GpuBuffer? _gpuBuffer;

  WebGPUBuffer(this.device, this.descriptor);

  /// Creates the GPU buffer on the hardware device.
  void create() {
    try {
      // Maps configuration straight to the gpux creation engine
      _gpuBuffer = device.createBuffer(
        size: descriptor.size,
        usage: descriptor.usage,
        label: descriptor.label,
        mappedAtCreation: descriptor.mappedAtCreation,
      );

      if (_gpuBuffer == null) {
        throw StateError("Buffer creation failed: GPU buffer handle returned null");
      }
    } catch (e) {
      console.error("ERROR: Buffer creation failed: ${e.toString()}");
      rethrow;
    }
  }

  /// Uploads vertex or uniform data to the buffer.
  /// @param data Data list to upload
  /// @param offset Offset location in bytes
  void upload(Float32List data, {int offset = 0}) {
    final bufferInstance = _gpuBuffer;
    if (bufferInstance == null) {
      throw StateError("Buffer not created. Call create() before uploading data.");
    }

    try {
      // Cast the TypedData view block into ByteData explicitly required by gpux queues
      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
      
      device.queue.writeBuffer(
        bufferInstance,
        byteData.buffer.asUint8List(), // gpux expects Uint8List for buffer uploads
        bufferOffset: offset,
      );
    } catch (e) {
      console.error("ERROR: Buffer data upload failed: ${e.toString()}");
      rethrow;
    }
  }

  /// Uploads 32-bit index data to the buffer.
  void uploadIndices(Uint32List data, {int offset = 0}) {
    final bufferInstance = _gpuBuffer;
    if (bufferInstance == null) {
      throw StateError("Buffer not created. Call create() before uploading indices.");
    }

    try {
      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
      
      device.queue.writeBuffer(
        bufferInstance,
        byteData.buffer.asUint8List(),
        bufferOffset: offset,
      );
    } catch (e) {
      console.error("ERROR: 32-bit index upload failed: ${e.toString()}");
      rethrow;
    }
  }

  /// Uploads 16-bit index data to the buffer (Uint16).
  void uploadIndices16(Uint16List data, {int offset = 0}) {
    final bufferInstance = _gpuBuffer;
    if (bufferInstance == null) {
      throw StateError("Buffer not created. Call create() before uploading 16-bit indices.");
    }

    try {
      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
      
      device.queue.writeBuffer(
        bufferInstance,
        byteData.buffer.asUint8List(),
        bufferOffset: offset, 
      );
    } catch (e) {
      console.error("ERROR: 16-bit index upload failed: ${e.toString()}");
      rethrow;
    }
  }

  /// Gets the raw underling GPU buffer handle.
  GpuBuffer? getBuffer() => _gpuBuffer;

  /// Returns the abstraction wrapper for this buffer if it was created.
  GpuBuffer? gpuBuffer() => _gpuBuffer;

  /// Gets buffer size in bytes.
  int getSize() => descriptor.size;

  /// Gets buffer usage flags.
  int getUsage() => descriptor.usage;

  /// Binds the buffer for rendering inside the active pass layout encoder.
  /// @param slot Binding slot/location index
  /// @param renderPass Core render pass layout encoder from gpux
  void bind({required int slot, required GpuRenderPassEncoder renderPass}) {
    final bufferInstance = _gpuBuffer;
    if (bufferInstance == null) return;

    // Check if GpuBufferUsage.vertex bits match
    if ((descriptor.usage & GpuBufferUsage.vertex) != 0) {
      renderPass.setVertexBuffer( slot, bufferInstance);
    } 
    // Check if GpuBufferUsage.index bits match
    else if ((descriptor.usage & GpuBufferUsage.index) != 0) {
      renderPass.setIndexBuffer(
        bufferInstance, 
        GpuIndexFormat.uint32, // Adjust format dynamically if you support 16-bit pipelines
      );
    }
  }

  /// Disposes the buffer and immediately releases the associated GPU hardware memory.
  void dispose() {
    _gpuBuffer?.destroy();
    _gpuBuffer = null;
  }
}

/// Mirroring parameter layout properties container matching original structure
class BufferDescriptor {
  final String label;
  final int size;
  final GpuBufferUsageFlags usage;
  final bool mappedAtCreation;

  const BufferDescriptor({
    required this.label,
    required this.size,
    required this.usage,
    this.mappedAtCreation = false,
  });
}
