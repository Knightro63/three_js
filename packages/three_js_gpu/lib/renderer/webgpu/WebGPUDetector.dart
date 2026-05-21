import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux package setup

/// WebGPU availability detector.
/// FR-001: WebGPU detection.
class WebGPUDetector {
  // Enforce non-instantiability to match Kotlin's object semantic
  WebGPUDetector._();

  /// Checks if WebGPU/WGPU is available on the current running platform.
  /// @return true if hardware bindings exist, false otherwise.
  static bool isAvailable() {
    try {
      // Replaces browser-bound js(" 'gpu' in navigator ") check.
      // gpux checks native library availability or canvas capabilities out of the box.
      return Gpu.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Gets the core hardware GPU orchestrator interface if available.
  /// @return Gpu reference instance, or null if unavailable.
  static Gpu? getGPU() {
    try {
      if (isAvailable()) {
        return Gpu(); // Returns the primary cross-platform entry handle wrapper
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
