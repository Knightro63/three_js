import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpu; // Adjust based on your exact gpu library paths

/// buffer manager implementation.
///
/// Manages GPU buffer lifecycle using GpuBuffer and device.queue.writeBuffer().
class BufferManager{
  late final gpu.HostBuffer host;

  // Track destroyed buffers to prevent double-destroy
  final Set<gpu.BufferView> _destroyedBuffers = {};

  GpuBufferManager(){
    host = gpu.gpuContext.createHostBuffer();
  }

  /// Create vertex buffer from float list data arrays.
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
      //   size: sizeBytes,
      //   usage: gpu.GpuBufferUsage.vertex | gpu.GpuBufferUsage.copyDst,
      //   mappedAtCreation: false,
      //   label: "vertex_buffer_${data.length}",
      // );

      // Prepare raw binary payload view block
      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
      final bufferWrapper = host.emplace(byteData);

      return BufferHandle(
        view: bufferWrapper,
        sizeBytes: sizeBytes,
        length: data.length,
        usage: BufferUsage.vertex,
        format: gpu.IndexType.int32
      );
    } on OutOfMemoryException {
      rethrow;
    } catch (e) {
      throw OutOfMemoryException("Unexpected error creating vertex buffer: ${e.toString()}");
    }
  }

  /// Create index buffer from integer list data arrays.
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
      
      // final bufferWrapper = device.createBuffer(
      //   size: sizeBytes,
      //   usage: gpu.GpuBufferUsage.index | gpu.GpuBufferUsage.copyDst,
      //   mappedAtCreation: false,
      //   label: "index_buffer_${data.length}",
      // );
      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
      final bufferWrapper = host.emplace(byteData);

      return BufferHandle(
        view: bufferWrapper,
        sizeBytes: sizeBytes,
        length: data.length,
        usage: BufferUsage.indx,
        format: gpu.IndexType.int32
      );
    } on OutOfMemoryException {
      rethrow;
    } catch (e) {
      throw OutOfMemoryException("Unexpected error creating index buffer: ${e.toString()}");
    }
  }

  /// Create uniform buffer with a fixed size constraint.
  BufferHandle createUniformBuffer(int sizeBytes) {
    int length = sizeBytes~/4;
    if (sizeBytes < 64) {
      throw ArgumentError(
        "uniformBuffer.sizeBytes must be at least 64 bytes (mat4x4), got $sizeBytes"
      );
    }

    try {
      // final bufferWrapper = device.createBuffer(
      //   size: sizeBytes,
      //   usage: gpu.GpuBufferUsage.uniform | gpu.GpuBufferUsage.copyDst,
      //   mappedAtCreation: false,
      //   label: "uniform_buffer_$sizeBytes",
      // );
      final data = Float32List(length).buffer.asByteData();
      final bufferWrapper = host.emplace(data);//.createHostBuffer(blockLengthInBytes: sizeBytes);

      return BufferHandle(
        view: bufferWrapper,
        length: length,
        sizeBytes: sizeBytes,
        usage: BufferUsage.uniform,
        format: gpu.IndexType.int32
      );
    } on OutOfMemoryException {
      rethrow;
    } catch (e) {
      throw OutOfMemoryException("Unexpected error creating uniform buffer: ${e.toString()}");
    }
  }

  /// Update uniform buffer data (transformation matrices).
  void updateUniformBuffer({
    required BufferHandle handle, 
    required Int8List data, 
    required int offset,
  }) {
    // Validate handle
    if (!handle.isValid()) {
      throw InvalidBufferException("Buffer handle is invalid (null handle or zero size)");
    }

    final buffer = handle.view;

    // Check if destroyed
    if (_destroyedBuffers.contains(buffer)) {
      throw InvalidBufferException("Buffer has been destroyed");
    }

    // Validate offset alignment (16-byte for mat4x4)
    if (offset % 16 != 0) {
      throw ArgumentError("offset must be 16-byte aligned, got $offset");
    }

    // Validate data size
    if (offset + data.length > handle.sizeBytes) {
      throw ArgumentError(
        "data too large: offset=$offset + size=${data.length} > buffer.size=${handle.sizeBytes}"
      );
    }

    try {
      final byteData = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
      buffer.buffer.overwrite(byteData);
      // device.queue.writeBuffer(
      //   buffer,
      //   byteData.buffer.asUint8List(),
      //   bufferOffset: offset,
      // );
    } catch (e) {
      throw InvalidBufferException("Failed to update uniform buffer: ${e.toString()}");
    }
  }

  /// Destroy buffer and release GPU memory safely.
  void destroyBuffer(BufferHandle handle) {
    final buffer = handle.view;
    if (buffer is! gpu.HostBuffer) {
      throw InvalidBufferException("Buffer handle is null or not a GpuBuffer");
    }

    // Check if already destroyed
    if (_destroyedBuffers.contains(buffer)) {
      throw InvalidBufferException("Buffer has already been destroyed");
    }

    try {
      // Destroy buffer from hardware layout execution space
      buffer.buffer.flush();
      
      // Mark as destroyed tracking state
      _destroyedBuffers.add(buffer);
    } catch (e) {
      throw InvalidBufferException("Failed to destroy buffer: ${e.toString()}");
    }
  }
}


enum BufferUsage { vertex, indx, uniform }

class BufferHandle {
  final gpu.BufferView view;
  final int sizeBytes;
  final int length;
  final BufferUsage usage;
  final gpu.IndexType format;

  const BufferHandle({
    required this.view,
    required this.sizeBytes,
    required this.usage,
    required this.format,
    required this.length
  });

  bool isValid() => sizeBytes > 0;
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
