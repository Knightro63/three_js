import 'dart:async';
import 'package:gpux/gpux.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import 'pipeline.dart';
import 'texture.dart';
import 'buffer.dart'; // Adjust based on your exact gpux library location

/// Resource descriptor types for tracking recreatable resources.
/// Replaces Kotlin's sealed class architecture using a clean abstract base.
abstract class ResourceDescriptor {
  const ResourceDescriptor();
}

class BufferDescriptorHolder extends ResourceDescriptor {
  final BufferDescriptor descriptor;
  const BufferDescriptorHolder(this.descriptor);
}

class TextureDescriptorHolder extends ResourceDescriptor {
  final TextureDescriptor descriptor;
  const TextureDescriptorHolder(this.descriptor);
}

class PipelineDescriptorHolder extends ResourceDescriptor {
  final RenderPipelineDescriptor descriptor;
  const PipelineDescriptorHolder(this.descriptor);
}

/// Context loss recovery manager.
/// T035: Automatically recovers from GPU context loss by recreating resources.
///
/// Handles driver crashes, tab backgrounding, and power management events.
class ContextLossRecovery {
  final List<ResourceDescriptor> _trackedResources = [];
  bool _isRecovering = false;
  int _lossCount = 0;

  // Callbacks
  void Function()? onContextLost;
  void Function()? onContextRestored;

  /// Tracks a resource for automatic recovery.
  void track(ResourceDescriptor descriptor) {
    _trackedResources.add(descriptor);
  }

  /// Tracks multiple resources.
  void trackAll(List<ResourceDescriptor> descriptors) {
    _trackedResources.addAll(descriptors);
  }

  /// Handles context loss event.
  void handleContextLoss() {
    if (_isRecovering) return;
    _lossCount++;
    _isRecovering = true;
    
    console.warning("WARNING: GPU context lost (event #$_lossCount)");
    onContextLost?.call();
  }

  /// Recovers all tracked resources with a new device.
  Future<RecoveryStats> recover(gpux.GpuDevice device) async {
    if (!_isRecovering) {
      return RecoveryStats(
        buffersRecreated: 0,
        texturesRecreated: 0,
        pipelinesRecreated: 0,
        failures: 0,
      );
    }

    console.info("INFO: Starting context recovery: ${_trackedResources.size} resources...");
    int buffersRecreated = 0;
    int texturesRecreated = 0;
    int pipelinesRecreated = 0;
    int failures = 0;

    // Recreate all tracked resources using Dart pattern matching
    for (final descriptor in _trackedResources) {
      try {
        switch (descriptor) {
          case BufferDescriptorHolder(descriptor: final desc):
            final buffer = GpuBuffer(device, desc);
            buffer.create();
            buffersRecreated++;
            break;
            
          case TextureDescriptorHolder(descriptor: final desc):
            final texture = GpuTexture(device, desc);
            texture.create();
            texturesRecreated++;
            break;
            
          case PipelineDescriptorHolder(descriptor: final desc):
            final pipeline = GpuPipeline(device, desc);
            pipeline.create();
            pipelinesRecreated++;
            break;
        }
      } catch (e) {
        console.error("ERROR: Failed to recreate resource: ${e.toString()}");
        failures++;
      }
    }

    final stats = RecoveryStats(
      buffersRecreated: buffersRecreated,
      texturesRecreated: texturesRecreated,
      pipelinesRecreated: pipelinesRecreated,
      failures: failures,
    );

    _isRecovering = false;

    if (failures > 0) {
      console.warning("WARNING: Context recovery completed with $failures failures");
      throw StateError("Recovery completed with $failures failures");
    } else {
      console.info("INFO: Context recovery successful: $stats");
      onContextRestored?.call();
      return stats;
    }
  }

  /// Clears all tracked resources.
  void clear() {
    _trackedResources.clear();
    _lossCount = 0;
    _isRecovering = false;
  }

  /// Gets the number of tracked resources.
  int getTrackedCount() => _trackedResources.length;

  /// Gets the number of context loss events.
  int getLossCount() => _lossCount;

  /// Checks if currently recovering.
  bool isRecovering() => _isRecovering;

  /// Monitors a GPU device for context loss.
  Future<void> monitorDevice(gpux.GpuDevice device) async {
    try {
      // Replaces device.lost.await with a standard future completion listener 
      // depending on how your specific gpux backend handles tracking events.
      await device.lost; 
      handleContextLoss();
    } catch (e) {
      console.error("ERROR: Error monitoring device loss: ${e.toString()}");
    }
  }
}

/// Recovery statistics container class.
class RecoveryStats {
  final int buffersRecreated;
  final int texturesRecreated;
  final int pipelinesRecreated;
  final int failures;

  RecoveryStats({
    required this.buffersRecreated,
    required this.texturesRecreated,
    required this.pipelinesRecreated,
    required this.failures,
  });

  int get total => buffersRecreated + texturesRecreated + pipelinesRecreated;

  double get successRate => total > 0 ? (total - failures).toDouble() / total : 1.0;

  @override
  String toString() {
    return 'RecoveryStats(buffers: $buffersRecreated, textures: $texturesRecreated, pipelines: $pipelinesRecreated, failures: $failures)';
  }
}

/// Helper extension to add standard length tracking naming properties to List collections
extension on List {
  int get size => length;
}
