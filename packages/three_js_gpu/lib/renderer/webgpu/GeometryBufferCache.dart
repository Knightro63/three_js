import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux library paths
import 'package:three_js_core/three_js_core.dart';
import '../geometry/GeometryDescriptor.dart';
import 'RenderStatsTracker.dart';
import 'WebGPUBuffer.dart'; // Adjust to where BufferGeometry lies

class _CacheKey {
  final String geometryId;
  final GeometryBuildOptions options;

  const _CacheKey(this.geometryId, this.options);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CacheKey &&
          runtimeType == other.runtimeType &&
          geometryId == other.geometryId &&
          options == other.options;

  @override
  int get hashCode => geometryId.hashCode ^ options.hashCode;
}

class GeometryBufferCache {
  final GpuDevice? Function() _deviceProvider;
  final RenderStatsTracker? _statsTracker;

  final Map<_CacheKey, GeometryBuffers> _buffersByGeometry = {};

  GeometryBufferCache({
    required GpuDevice? Function() deviceProvider,
    RenderStatsTracker? statsTracker,
  })  : _deviceProvider = deviceProvider,
        _statsTracker = statsTracker;

  GeometryBuffers? getOrCreate({
    required BufferGeometry geometry,
    required int frameCount,
    required GeometryBuildOptions options,
  }) {
    final key = _CacheKey(geometry.uuid, options);
    
    if (_buffersByGeometry.containsKey(key)) {
      return _buffersByGeometry[key];
    }

    final gpuDevice = _deviceProvider();
    if (gpuDevice == null) {
      print("ERROR: WebGPU device unavailable when creating geometry buffers");
      return null;
    }

    try {
      final geometryBuffer = GeometryBuilder.build(geometry, options: options);
      
      final List<StreamBuffer> vertexStreams = [];
      for (int index = 0; index < geometryBuffer.streams.length; index++) {
        final stream = geometryBuffer.streams[index];
        final byteLength = stream.data.length * 4; // Float32 elements are 4 bytes each

        final vertexBuffer = WebGPUBuffer(
          gpuDevice,
          BufferDescriptor(
            size: byteLength,
            usage: GpuBufferUsage.vertex | GpuBufferUsage.copyDst,
            label: "Vertex Stream $index for ${geometry.uuid}",
          ),
        );
        
        vertexBuffer.create();
        vertexBuffer.upload(stream.data);
        _statsTracker?.recordBufferAllocated(byteLength);

        vertexStreams.add(StreamBuffer(
          buffer: vertexBuffer.getBuffer()!,
          sizeBytes: byteLength,
          layout: stream.layout,
        ));
      }

      GpuBuffer? indexBuffer;
      int indexSizeBytes = 0;
      final indexData = geometryBuffer.indexData;

      if (indexData != null) {
        indexSizeBytes = indexData.length * 4; // Uint32 indices are 4 bytes each
        
        final buffer = WebGPUBuffer(
          gpuDevice,
          BufferDescriptor(
            size: indexSizeBytes,
            usage: GpuBufferUsage.index | GpuBufferUsage.copyDst,
            label: "Index Buffer ${geometry.uuid}",
          ),
        );
        
        buffer.create();
        buffer.uploadIndices(indexData);
        indexBuffer = buffer.getBuffer();
        
        _statsTracker?.recordBufferAllocated(indexSizeBytes);
      }

      final buffers = GeometryBuffers(
        vertexStreams: vertexStreams,
        indexBuffer: indexBuffer,
        indexBufferSize: indexSizeBytes,
        vertexCount: geometryBuffer.vertexCount,
        indexCount: geometryBuffer.indexCount,
        indexFormat: GpuIndexFormat.uint32, // maps straight to gpux's strongly-typed enum
        instanceCount: geometryBuffer.instanceCount,
        metadata: geometryBuffer.metadata,
      );

      _buffersByGeometry[key] = buffers;
      return buffers;
    } catch (e) {
      print("ERROR: Failed to create geometry buffers: ${e.toString()}");
      return null;
    }
  }

  void clear() {
    for (final buffers in _buffersByGeometry.values) {
      for (final stream in buffers.vertexStreams) {
        try {
          _statsTracker?.recordBufferDeallocated(stream.sizeBytes);
          stream.buffer.destroy();
        } catch (_) {
          // ignored
        }
      }
      
      try {
        final indexBuffer = buffers.indexBuffer;
        if (indexBuffer != null) {
          _statsTracker?.recordBufferDeallocated(buffers.indexBufferSize);
          indexBuffer.destroy();
        }
      } catch (_) {
        // ignored
      }
    }
    _buffersByGeometry.clear();
  }
}

class GeometryBuffers {
  final List<StreamBuffer> vertexStreams;
  final GpuBuffer? indexBuffer;
  final int indexBufferSize;
  final int vertexCount;
  final int indexCount;
  final GpuIndexFormat indexFormat;
  final int instanceCount;
  final GeometryMetadata metadata;

  GeometryBuffers({
    required this.vertexStreams,
    this.indexBuffer,
    required this.indexBufferSize,
    required this.vertexCount,
    required this.indexCount,
    required this.indexFormat,
    required this.instanceCount,
    required this.metadata,
  });
}

class StreamBuffer {
  final GpuBuffer buffer;
  final int sizeBytes;
  final GpuVertexBufferLayout layout;

  StreamBuffer({
    required this.buffer,
    required this.sizeBytes,
    required this.layout,
  });
}
