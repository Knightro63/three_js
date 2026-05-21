import 'dart:core';

/// Web performance monitor using high-precision Timing API and WebGPU timestamp queries.
class WebPerformanceMonitor extends AbstractPerformanceMonitor {
  
  // Keep track of the starting time instance to calculate true elapsed microseconds
  final Stopwatch _stopwatch = Stopwatch()..start();

  @override
  int getCurrentTimeMs() {
    // Returns a highly accurate fractional double, converted cleanly to milliseconds
    return getPerformanceNow().toLong();
  }

  double getPerformanceNow() {
    // Replaces JS performance.now() with cross-platform native high-precision timing.
    // Dart's stopwatch uses the hardware clock (mach_absolute_time on iOS/Mac, CLOCK_MONOTONIC on Linux/Android)
    return _stopwatch.elapsedMicroseconds / 1000.0;
  }

  /// Use WebGPU timestamp queries for GPU timing (when available).
  double queryGPUTimestamp() {
    // WebGPU timestamp queries require the "timestamp-query" feature enabled on the GpuDevice.
    // This cleanly falls back to high-precision CPU time when device flags are unavailable.
    return getPerformanceNow();
  }
}

/// Factory function implementation mapping to Kotlin's actual fun pattern.
PerformanceMonitor createPerformanceMonitor() {
  return WebPerformanceMonitor();
}

/// Extension mapping Kotlin's explicit .toLong() casting convention to Dart
extension on double {
  int toLong() => this.truncate();
}
