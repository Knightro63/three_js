enum BackendType {
  /// WebGPU - Primary for JavaScript/browser targets.
  /// Modern GPU API available in Chrome 113+, Edge 113+.
  webgpu,

  /// Vulkan - Primary for JVM/Native targets.
  /// Cross-platform, low-overhead GPU API.
  vulkan,

  /// WebGL 2.0 - Fallback only for browser compatibility.
  /// Used when WebGPU is unavailable (older browsers, experimental flags disabled).
  webgl;

  /// Returns true if this is a primary backend (WebGPU or Vulkan).
  ///
  /// Primary backends are preferred for performance and features.
  bool get isPrimary => this == BackendType.webgpu || this == BackendType.vulkan;

  /// Returns true if this is a fallback backend (WebGL).
  ///
  /// Fallback backends are used only when primary backends are unavailable.
  bool get isFallback => this == BackendType.webgl;
}
