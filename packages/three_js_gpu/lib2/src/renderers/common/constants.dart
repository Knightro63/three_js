/// Collection of layout parameters and structural geometry type flags.
enum AttributeType {
  none,
  vertex,
  indx,
  storage,
  indirect
}

/// Size of a memory chunk in bytes matching WebGPU STD140 layout alignment rules.
const int gpuChunkBytes = 16;

/// Custom color blend factor identifier mapping track.
const int blendColorFactor = 211;

/// Inverted color blend factor identifier mapping track.
const int oneMinusBlendColorFactor = 212;
