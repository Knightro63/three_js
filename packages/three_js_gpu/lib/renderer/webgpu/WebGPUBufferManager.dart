import 'dart:typed_data';
import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux library paths

/// WebGPU buffer manager implementation.
///
/// Manages GPU buffer lifecycle using GpuBuffer and device.queue.writeBuffer().
class WebGPUBufferManager implements BufferManager {
  final GpuDevice device;

  // Track destroyed buffers to prevent double-destroy
  final Set<GpuBuffer> _destroyedBuffers = {};

  WebGPUBufferManager(this.device);

  /// Create vertex buffer from float list data arrays.
  @override
  BufferHandle createVertexBuffer(Float32List data) {
    if (data.isEmpty) {
      throw ArgumentError("Vertex data cannot be empty");
    }
    // Data must be multiple of 6 floats (position + color)
    if (data.length % 6 != 0) {
      throw ArgumentError(
        "vertexData.size must be multiple of 6 (position + color), got ${data.length}"
      );
    }

    final sizeBytes = data.length * 4; // 4 bytes per float
    try {
      final bufferWrapper = device.createBuffer(
        size: sizeBytes,
        usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
        mappedAtCreation: false,
        label: "vertex_buffer_${data.length}",
      );

      // Prepare raw binary payload view block
      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);

      device.queue.writeBuffer(
        bufferWrapper,
        byteData.buffer.asUint8List(),
        bufferOffset: 0,
      );

      return BufferHandle(
        handle: bufferWrapper,
        size: sizeBytes,
        usage: BufferUsage.vertex,
      );
    } on OutOfMemoryException {
      rethrow;
    } catch (e) {
      throw OutOfMemoryException("Unexpected error creating vertex buffer: ${e.toString()}");
    }
  }

  /// Create index buffer from integer list data arrays.
  @override
  BufferHandle createIndexBuffer(Uint32List data) {
    if (data.isEmpty) {
      throw ArgumentError("Index data cannot be empty");
    }
    if (data.length % 3 != 0) {
      throw ArgumentError(
        "indexData.size must be multiple of 3 (triangles), got ${data.length}"
      );
    }

    final sizeBytes = data.length * 4; // 4 bytes per uint32
    try {
      final bufferWrapper = device.createBuffer(
        size: sizeBytes,
        usage: GpuBufferUsage.index | GpuBufferUsage.copyDst,
        mappedAtCreation: false,
        label: "index_buffer_${data.length}",
      );

      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);

      device.queue.writeBuffer(
       bufferWrapper,
       byteData.buffer.asUint8List(),
        bufferOffset: 0,
      );

      return BufferHandle(
        handle: bufferWrapper,
        size: sizeBytes,
        usage: BufferUsage.indx,
      );
    } on OutOfMemoryException {
      rethrow;
    } catch (e) {
      throw OutOfMemoryException("Unexpected error creating index buffer: ${e.toString()}");
    }
  }

  /// Create uniform buffer with a fixed size constraint.
  @override
  BufferHandle createUniformBuffer(int sizeBytes) {
    if (sizeBytes < 64) {
      throw ArgumentError(
        "uniformBuffer.sizeBytes must be at least 64 bytes (mat4x4), got $sizeBytes"
      );
    }

    try {
      final bufferWrapper = device.createBuffer(
        size: sizeBytes,
        usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
        mappedAtCreation: false,
        label: "uniform_buffer_$sizeBytes",
      );

      return BufferHandle(
        handle: bufferWrapper,
        size: sizeBytes,
        usage: BufferUsage.uniform,
      );
    } on OutOfMemoryException {
      rethrow;
    } catch (e) {
      throw OutOfMemoryException("Unexpected error creating uniform buffer: ${e.toString()}");
    }
  }

  /// Update uniform buffer data (transformation matrices).
  @override
  void updateUniformBuffer({
    required BufferHandle handle, 
    required Int8List data, 
    required int offset,
  }) {
    // Validate handle
    if (!handle.isValid()) {
      throw InvalidBufferException("Buffer handle is invalid (null handle or zero size)");
    }

    final buffer = handle.handle;
    if (buffer is! GpuBuffer) {
      throw InvalidBufferException("Buffer handle is null or not a GpuBuffer");
    }

    // Check if destroyed
    if (_destroyedBuffers.contains(buffer)) {
      throw InvalidBufferException("Buffer has been destroyed");
    }

    // Validate offset alignment (16-byte for mat4x4)
    if (offset % 16 != 0) {
      throw ArgumentError("offset must be 16-byte aligned, got $offset");
    }

    // Validate data size
    if (offset + data.length > handle.size) {
      throw ArgumentError(
        "data too large: offset=$offset + size=${data.length} > buffer.size=${handle.size}"
      );
    }

    try {
      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);

      device.queue.writeBuffer(
        buffer,
        byteData.buffer.asUint8List(),
        bufferOffset: offset,
      );
    } catch (e) {
      throw InvalidBufferException("Failed to update uniform buffer: ${e.toString()}");
    }
  }

  /// Destroy buffer and release GPU memory safely.
  @override
  void destroyBuffer(BufferHandle handle) {
    final buffer = handle.handle;
    if (buffer is! GpuBuffer) {
      throw InvalidBufferException("Buffer handle is null or not a GpuBuffer");
    }

    // Check if already destroyed
    if (_destroyedBuffers.contains(buffer)) {
      throw InvalidBufferException("Buffer has already been destroyed");
    }

    try {
      // Destroy buffer from hardware layout execution space
      buffer.destroy();
      
      // Mark as destroyed tracking state
      _destroyedBuffers.add(buffer);
    } catch (e) {
      throw InvalidBufferException("Failed to destroy buffer: ${e.toString()}");
    }
  }
}

// ==========================================
// ABSTRACT CONTRACT SPECIFICATION DECLARATIONS
// ==========================================

abstract class BufferManager {
  BufferHandle createVertexBuffer(Float32List data);
  BufferHandle createIndexBuffer(Uint32List data);
  BufferHandle createUniformBuffer(int sizeBytes);
  void updateUniformBuffer({required BufferHandle handle, required Int8List data, required int offset});
  void destroyBuffer(BufferHandle handle);
}

enum BufferUsage { vertex, indx, uniform }

class BufferHandle {
  final dynamic handle;
  final int size;
  final BufferUsage usage;

  const BufferHandle({
    required this.handle,
    required this.size,
    required this.usage,
  });

  bool isValid() => handle != null && size > 0;
}

// Custom Exceptions replacing Kotlin definitions
class OutOfMemoryException implements Exception {
  final String message;
  const OutOfMemoryException(this.message);
  @override
  String toString() => "OutOfMemoryException: $message";
}

class InvalidBufferException implements Exception {
  final String message;
  const InvalidBufferException(this.message);
  @override
  String toString() => "InvalidBufferException: $message";
}
