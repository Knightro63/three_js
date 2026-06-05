import 'package:gpux/gpux.dart' as gpux; // Adjust based on your exact gpux package setup

/// availability detector.
/// FR-001: detection.
class GpuDetector {
  // Enforce non-instantiability to match Kotlin's object semantic
  GpuDetector._();

  /// Checks if GPU is available on the current running platform.
  /// @return true if hardware bindings exist, false otherwise.
  static bool isAvailable() {
    try {
      // Replaces browser-bound js(" 'gpu' in navigator ") check.
      // gpux checks native library availability or canvas capabilities out of the box.
      gpux.Gpu().requestAdapter(); // Checks cross-platform hardware binding flags via gpux
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gets the core hardware GPU orchestrator interface if available.
  /// @return Gpu reference instance, or null if unavailable.
  static gpux.Gpu? getGPU() {
    try {
      if (isAvailable()) {
        return gpux.Gpu(); // Returns the primary cross-platform entry handle wrapper
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
