import 'dart:math' as math;

/// Lightweight profiler for the CPU-side IBL convolution pipeline. Collects
/// timing information for irradiance and prefilter passes so that renderers can
/// surface the information in performance HUDs or stats panels.
abstract class IBLConvolutionProfiler {
  static double _prefilterMs = 0.0;
  static double _irradianceMs = 0.0;
  static int _prefilterSamples = 0;
  static int _irradianceSamples = 0;
  static int _prefilterSize = 0;
  static int _irradianceSize = 0;
  static int _prefilterMipCount = 0;
  static int _lastTimestamp = 0;

  /// Records the latest prefilter pass metrics.
  static void recordPrefilter({
    required double durationMs,
    required int size,
    required int mipCount,
    required int sampleCount,
  }) {
    _prefilterMs = durationMs;
    _prefilterSize = size;
    _prefilterMipCount = math.max(1, mipCount);
    _prefilterSamples = sampleCount;
    _lastTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  /// Records the latest irradiance pass metrics.
  static void recordIrradiance({
    required double durationMs,
    required int size,
    required int sampleCount,
  }) {
    _irradianceMs = durationMs;
    _irradianceSize = size;
    _irradianceSamples = sampleCount;
    _lastTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  /// Returns the most recent convolution profile snapshot.
  static IBLConvolutionMetrics snapshot() {
    return IBLConvolutionMetrics(
      prefilterMs: _prefilterMs,
      irradianceMs: _irradianceMs,
      prefilterSamples: _prefilterSamples,
      irradianceSamples: _irradianceSamples,
      prefilterSize: _prefilterSize,
      irradianceSize: _irradianceSize,
      prefilterMipCount: _prefilterMipCount,
      timestamp: _lastTimestamp,
    );
  }
}

/// Data carrier for the latest IBL convolution metrics.
class IBLConvolutionMetrics {
  const IBLConvolutionMetrics({
    required this.prefilterMs,
    required this.irradianceMs,
    required this.prefilterSamples,
    required this.irradianceSamples,
    required this.prefilterSize,
    required this.irradianceSize,
    required this.prefilterMipCount,
    required this.timestamp,
  });

  final double prefilterMs;
  final double irradianceMs;
  final int prefilterSamples;
  final int irradianceSamples;
  final int prefilterSize;
  final int irradianceSize;
  final int prefilterMipCount;
  final int timestamp; // Maps to Long via Dart's 64-bit int primitive

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IBLConvolutionMetrics &&
          runtimeType == other.runtimeType &&
          prefilterMs == other.prefilterMs &&
          irradianceMs == other.irradianceMs &&
          prefilterSamples == other.prefilterSamples &&
          irradianceSamples == other.irradianceSamples &&
          prefilterSize == other.prefilterSize &&
          irradianceSize == other.irradianceSize &&
          prefilterMipCount == other.prefilterMipCount &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        prefilterMs,
        irradianceMs,
        prefilterSamples,
        irradianceSamples,
        prefilterSize,
        irradianceSize,
        prefilterMipCount,
        timestamp,
      );

  @override
  String toString() {
    return 'IBLConvolutionMetrics(prefilterMs: $prefilterMs, irradianceMs: $irradianceMs, prefilterSamples: $prefilterSamples, irradianceSamples: $irradianceSamples, prefilterSize: $prefilterSize, irradianceSize: $irradianceSize, prefilterMipCount: $prefilterMipCount, timestamp: $timestamp)';
  }
}
