import 'dart:typed_data';

import 'package:gpux/gpux.dart';
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_math/three_js_math.dart' as math;

// gpux backend descriptor and utility imports
import '../../common/timestamp_query_pool.dart';
import './gpu_utils.dart';
import '../descriptors/gpu_buffer_descriptor.dart';
import '../descriptors/gpu_command_encoder_descriptor.dart';
import '../descriptors/gpu_query_set_descriptor.dart';

// File-scope shared descriptors
final GPUBufferDescriptor _bufferDescriptor = GPUBufferDescriptor();
final GPUCommandEncoderDescriptor _commandEncoderDescriptor = GPUCommandEncoderDescriptor();
final GPUQuerySetDescriptor _querySetDescriptor = GPUQuerySetDescriptor();

/// Manages a pool of WebGPU timestamp queries for performance measurement.
/// Extends the base TimestampQueryPool to provide WebGPU-specific implementation.
class WebGPUTimestampQueryPool extends TimestampQueryPool {
  dynamic device;
  String type;
  dynamic querySet;
  dynamic resolveBuffer;
  dynamic resultBuffer;

  // internal state tracking maps
  final Map<String, int> queryOffsets = {};
  final Map<String, double> timestamps = {};
  Future<double>? pendingResolve;

  // Local state backing cache following map instructions strategy
  final Map<String, dynamic> _poolStateCache = {};
  dynamic operator [](String key) => _poolStateCache[key];
  void operator []=(String key, dynamic value) => _poolStateCache[key] = value;

  /// Creates a new WebGPU timestamp query pool.
  WebGPUTimestampQueryPool(this.device, this.type, [int maxQueries = 2048]) : super(maxQueries) {
    _querySetDescriptor.label = 'queryset_global_timestamp_$type';
    _querySetDescriptor.type = 'timestamp';
    _querySetDescriptor.count = this.maxQueries;
    
    this.querySet = this.device.createQuerySet(_querySetDescriptor);
    _querySetDescriptor.reset();

    final int bufferSize = this.maxQueries * 8;
    _bufferDescriptor.label = 'buffer_timestamp_resolve_$type';
    _bufferDescriptor.size = bufferSize;
    _bufferDescriptor.usage = GpuBufferUsage.queryResolve | GpuBufferUsage.copySrc;
    
    this.resolveBuffer = this.device.createBuffer(_bufferDescriptor);
    _bufferDescriptor.reset();

    _bufferDescriptor.label = 'buffer_timestamp_result_$type';
    _bufferDescriptor.size = bufferSize;
    _bufferDescriptor.usage = GpuBufferUsage.copyDst | GpuBufferUsage.mapRead;
    
    this.resultBuffer = this.device.createBuffer(_bufferDescriptor);
    _bufferDescriptor.reset();
  }

  /// Allocates a pair of queries for a given render context.
  int? allocateQueriesForContext(String uid) {
    if (this.trackTimestamp != true || this.isDisposed == true) return null;
    
    if (this.currentQueryIndex + 2 > this.maxQueries) {
      core.console.warning(
        'WebGPUTimestampQueryPool [${this.type}]: Maximum number of queries exceeded, '
        'when using trackTimestamp it is necessary to resolves the queries via '
        'renderer.resolveTimestampsAsync( THREE.TimestampQuery.${this.type.toUpperCase()} ).'
      );
      return null;
    }

    final int baseOffset = this.currentQueryIndex;
    this.currentQueryIndex += 2;
    this.queryOffsets[uid] = baseOffset;
    
    return baseOffset;
  }

  /// Asynchronously resolves all pending queries and returns the total duration.
  /// If there's already a pending resolve operation, returns that promise instead.
  Future<double> resolveQueriesAsync() async {
    if (this.trackTimestamp != true || this.currentQueryIndex == 0 || this.isDisposed == true) {
      return this.lastValue.toDouble();
    }

    if (this.pendingResolve != null) {
      return this.pendingResolve!;
    }

    this.pendingResolve = this._resolveQueries();
    try {
      final double result = await this.pendingResolve!;
      return result;
    } finally {
      this.pendingResolve = null;
    }
  }

  /// Internal method to resolve queries and calculate total duration.
  Future<double> _resolveQueries() async {
    if (this.isDisposed == true) {
      return this.lastValue.toDouble();
    }

    try {
      if (this.resultBuffer.mapState != 'unmapped') {
        return this.lastValue.toDouble();
      }

      final Map<String, int> currentOffsets = Map<String, int>.from(this.queryOffsets);
      final int queryCount = this.currentQueryIndex;
      final int bytesUsed = queryCount * 8;

      // Reset state before GPU work execution begins
      this.currentQueryIndex = 0;
      this.queryOffsets.clear();

      final dynamic commandEncoder = this.device.createCommandEncoder(_commandEncoderDescriptor);
      commandEncoder.resolveQuerySet(this.querySet, 0, queryCount, this.resolveBuffer, 0);
      commandEncoder.copyBufferToBuffer(this.resolveBuffer, 0, this.resultBuffer, 0, bytesUsed);
      
      final dynamic commandBuffer = commandEncoder.finish();
      submit(this.device, commandBuffer);

      if (this.resultBuffer.mapState != 'unmapped') {
        return this.lastValue.toDouble();
      }

      // Create and track the asynchronous hardware mapping operation
      await this.resultBuffer.mapAsync(GPUMapMode.read, 0, bytesUsed);

      if (this.isDisposed == true) {
        if (this.resultBuffer.mapState == 'mapped') {
          this.resultBuffer.unmap();
        }
        return this.lastValue.toDouble();
      }

      // Extract the raw binary payload array view from the mapped region
      final dynamic arrayBuffer = this.resultBuffer.getMappedRange(0, bytesUsed);
      final ByteData times = ByteData.view(arrayBuffer);
      
      final Map<int, double> framesDuration = {};
      final List<int> frames = [];

      // Regex tracking string matcher: maps exactly to standard JS pattern /^(.*):f(\d+)$/
      final RegExp frameRegex = RegExp(r'^(.*):f(\d+)$');

      for (final Entry<String, int> entry in currentOffsets.entries) {
        final String uid = entry.key;
        final int baseOffset = entry.value;

        final Match? match = frameRegex.firstMatch(uid);
        if (match != null) {
          final int frame = int.parse(match.group(2)!);

          if (!frames.contains(frame)) {
            frames.add(frame);
          }

          if (framesDuration[frame] == null) {
            framesDuration[frame] = 0.0;
          }

          // Reads 8-byte uint64 numbers sequentially from byte view streams
          final int startByteOffset = baseOffset * 8;
          final int endByteOffset = (baseOffset + 1) * 8;
          
          final int startTime = times.getUint64(startByteOffset, Endian.little);
          final int endTime = times.getUint64(endByteOffset, Endian.little);

          // Calculate time gap converting nanosecond delta ticks into milliseconds
          final double duration = (endTime - startTime).toDouble() / 1e6;
          this.timestamps[uid] = duration;
          framesDuration[frame] = framesDuration[frame]! + duration;
        }
      }

      // Extract the total duration of the last recorded camera frame
      double totalDuration = 0.0;
      if (frames.isNotEmpty) {
        final int lastFrame = frames.last;
        totalDuration = framesDuration[lastFrame] ?? 0.0;
      }

      this.resultBuffer.unmap();
      this.lastValue = totalDuration;
      this.frames = frames; // Assign completed frames collection cache reference
      
      return totalDuration;
    } catch (e, stack) {
      core.console.error('Error resolving queries: $e', e, stack);
      if (this.resultBuffer.mapState == 'mapped') {
        this.resultBuffer.unmap();
      }
      return this.lastValue.toDouble();
    }
  }

  /// Dispose of the query pool, unmapping buffers and freeing active sets.
  @override
  Future<void> dispose() async {
    if (this.isDisposed == true) {
      return;
    }
    this.isDisposed = true;

    // Wait for ongoing asynchronous map operations before dismantling context pipelines
    if (this.pendingResolve != null) {
      try {
        await this.pendingResolve;
      } catch (e, stack) {
        core.console.error('Error waiting for pending resolve: $e', e, stack);
      }
    }

    // Ensure backing graphics buffer is cleanly unmapped before destruction steps
    if (this.resultBuffer != null && this.resultBuffer.mapState == 'mapped') {
      try {
        this.resultBuffer.unmap();
      } catch (e, stack) {
        core.console.error('Error unmapping buffer during pool disposal: $e', e, stack);
      }
    }

    // Destroy active hardware query sets and allocations
    if (this.querySet != null) {
      this.querySet.destroy();
      this.querySet = null;
    }
    if (this.resolveBuffer != null) {
      this.resolveBuffer.destroy();
      this.resolveBuffer = null;
    }
    if (this.resultBuffer != null) {
      this.resultBuffer.destroy();
      this.resultBuffer = null;
    }

    this.queryOffsets.clear();
    this.timestamps.clear();
    this._poolStateCache.clear();
    this.pendingResolve = null;
    
    super.dispose();
  }
}

// Map entry model helper abstraction targeting Map processing entries loops
class Entry<K, V> {
  final K key;
  final V value;
  Entry(this.key, this.value);
}
