import 'dart:async';
import 'package:gpux/gpux.dart';
import 'WebGPUPipeline.dart'; // Adjust based on your exact gpux library paths

/// Pipeline cache key for identifying unique pipeline configurations.
class PipelineKey {
  final int vertexShaderHash;
  final int fragmentShaderHash;
  final int vertexLayoutsHash;
  final GpuPrimitiveTopology primitiveTopology;
  final GpuCullMode cullMode;
  final GpuFrontFace frontFace;
  final GpuDepthStencilState? depthStencilState;
  final GpuMultisampleState? multisampleState;
  final GpuColorTargetDescriptor colorTarget;

  const PipelineKey({
    required this.vertexShaderHash,
    required this.fragmentShaderHash,
    required this.vertexLayoutsHash,
    required this.primitiveTopology,
    required this.cullMode,
    required this.frontFace,
    this.depthStencilState,
    this.multisampleState,
    required this.colorTarget,
  });

  /// Creates a pipeline key from a descriptor.
  factory PipelineKey.fromDescriptor(RenderPipelineDescriptor descriptor) {
    return PipelineKey(
      vertexShaderHash: descriptor.vertexShader.hashCode,
      fragmentShaderHash: descriptor.fragmentShader.hashCode,
      vertexLayoutsHash: descriptor.vertexLayouts.hashCode,
      primitiveTopology: descriptor.primitiveTopology,
      cullMode: descriptor.cullMode,
      frontFace: descriptor.frontFace,
      depthStencilState: descriptor.depthStencilState,
      multisampleState: descriptor.multisampleState,
      colorTarget: descriptor.colorTarget,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineKey &&
          runtimeType == other.runtimeType &&
          vertexShaderHash == other.vertexShaderHash &&
          fragmentShaderHash == other.fragmentShaderHash &&
          vertexLayoutsHash == other.vertexLayoutsHash &&
          primitiveTopology == other.primitiveTopology &&
          cullMode == other.cullMode &&
          frontFace == other.frontFace &&
          depthStencilState == other.depthStencilState &&
          multisampleState == other.multisampleState &&
          colorTarget == other.colorTarget;

  @override
  int get hashCode => Object.hash(
        vertexShaderHash,
        fragmentShaderHash,
        vertexLayoutsHash,
        primitiveTopology,
        cullMode,
        frontFace,
        depthStencilState,
        multisampleState,
        colorTarget,
      );
}

/// Pipeline cache for storing compiled pipelines.
/// T033: Avoids redundant pipeline compilation.
///
/// Critical for performance - can improve FPS by 8-15 frames.
class PipelineCache {
  final Map<PipelineKey, WebGPUPipeline> _cache = {};
  int _hitCount = 0;
  int _missCount = 0;

  /// Gets a pipeline from cache or creates a new one via a factory lambda.
  /// @param key Pipeline key
  /// @param factory Factory function to create pipeline on cache miss
  /// @return Cached or newly created pipeline
  Future<WebGPUPipeline> getOrCreate({
    required PipelineKey key,
    required Future<WebGPUPipeline> Function() factory,
  }) async {
    final cachedPipeline = _cache[key];
    
    if (cachedPipeline != null) {
      _hitCount++;
      return cachedPipeline;
    }

    _missCount++;
    final newPipeline = await factory();
    _cache[key] = newPipeline;
    return newPipeline;
  }

  /// Gets a pipeline from cache or creates it asynchronously from a descriptor block.
  Future<WebGPUPipeline> getOrCreateFromDescriptor({
    required GpuDevice device, // Maps from original GPUDevice interface
    required RenderPipelineDescriptor descriptor,
  }) async {
    final key = PipelineKey.fromDescriptor(descriptor);
    
    return getOrCreate(
      key: key,
      factory: () async {
        final pipeline = WebGPUPipeline(device, descriptor);
        pipeline.create();
        return pipeline;
      },
    );
  }

  /// Checks if a pipeline exists in cache.
  bool has(PipelineKey key) => _cache.containsKey(key);

  /// Clears the entire cache (e.g., on context loss).
  void clear() {
    for (final pipeline in _cache.values) {
      pipeline.dispose();
    }
    _cache.clear();
    _hitCount = 0;
    _missCount = 0;
  }

  /// Gets cache statistics.
  CacheStats getStats() {
    final totalRequests = _hitCount + _missCount;
    final floatHitRate = totalRequests > 0 ? _hitCount.toDouble() / totalRequests : 0.0;

    return CacheStats(
      size: _cache.length,
      hits: _hitCount,
      misses: _missCount,
      hitRate: floatHitRate,
    );
  }

  /// Removes a specific pipeline from cache and disposes its graphics memory bindings.
  WebGPUPipeline? remove(PipelineKey key) {
    final pipeline = _cache.remove(key);
    pipeline?.dispose();
    return pipeline;
  }

  /// Gets the number of cached pipelines.
  int size() => _cache.length;
}

/// Cache statistics metadata container.
class CacheStats {
  final int size;
  final int hits;
  final int misses;
  final double hitRate;

  const CacheStats({
    required this.size,
    required this.hits,
    required this.misses,
    required this.hitRate,
  });

  @override
  String toString() {
    return 'CacheStats(size: $size, hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
