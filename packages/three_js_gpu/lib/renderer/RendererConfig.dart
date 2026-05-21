import 'BackendType.dart';

/// GPU power preference for renderer initialization.
enum PowerPreference {
  /// Prefer integrated GPU (lower power consumption).
  lowPower,

  /// Prefer discrete GPU (higher performance).
  /// Recommended for 60 FPS target (FR-019).
  highPerformance,
}

/// Configuration for renderer initialization.
class RendererConfig {
  RendererConfig({
    this.preferredBackend,
    this.enableValidation = true,
    this.vsync = true,
    this.msaaSamples = 4,
    this.powerPreference = PowerPreference.highPerformance,
  }) {
    // Validate msaaSamples is power of 2
    assert(
      const {1, 2, 4, 8, 16}.contains(msaaSamples),
      'msaaSamples must be power of 2 (1, 2, 4, 8, 16), got: $msaaSamples',
    );

    // Warn if preferredBackend is webgl (violates FR-001/FR-002)
    if (preferredBackend == BackendType.webgl) {
      print('⚠️ Warning: Explicitly requesting WebGL backend (should only be fallback per FR-001/FR-002)');
    }
  }

  /// Preferred graphics backend (null = auto-detect)
  final BackendType? preferredBackend;

  /// Enable debug/validation layers
  final bool enableValidation;

  /// Enable V-sync for frame pacing
  final bool vsync;

  /// MSAA sample count (must be power of 2: 1, 2, 4, 8, 16)
  final int msaaSamples;

  /// GPU power preference (high-performance vs low-power)
  final PowerPreference powerPreference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RendererConfig &&
          runtimeType == other.runtimeType &&
          preferredBackend == other.preferredBackend &&
          enableValidation == other.enableValidation &&
          vsync == other.vsync &&
          msaaSamples == other.msaaSamples &&
          powerPreference == other.powerPreference;

  @override
  int get hashCode => Object.hash(
        preferredBackend,
        enableValidation,
        vsync,
        msaaSamples,
        powerPreference,
      );

  /// Helper to allow clean copy-with operations typical of data classes
  RendererConfig copyWith({
    BackendType? preferredBackend,
    bool? enableValidation,
    bool? vsync,
    int? msaaSamples,
    PowerPreference? powerPreference,
  }) {
    return RendererConfig(
      preferredBackend: preferredBackend ?? this.preferredBackend,
      enableValidation: enableValidation ?? this.enableValidation,
      vsync: vsync ?? this.vsync,
      msaaSamples: msaaSamples ?? this.msaaSamples,
      powerPreference: powerPreference ?? this.powerPreference,
    );
  }
}
