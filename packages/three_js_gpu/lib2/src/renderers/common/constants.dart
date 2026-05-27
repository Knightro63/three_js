/// Collection of layout parameters and structural geometry type flags.
abstract class AttributeType {
  /// Vertex buffer shader layout attribute.
  static const int vertex = 1;

  /// Index buffer shader layout attribute.
  static const int index = 2;

  /// Storage buffer shader layout attribute.
  static const int storage = 3;

  /// Indirect execution storage buffer shader layout attribute.
  static const int indirect = 4;
}

/// Size of a memory chunk in bytes matching WebGPU STD140 layout alignment rules.
const int gpuChunkBytes = 16;

/// Custom color blend factor identifier mapping track.
const int blendColorFactor = 211;

/// Inverted color blend factor identifier mapping track.
const int oneMinusBlendColorFactor = 212;
