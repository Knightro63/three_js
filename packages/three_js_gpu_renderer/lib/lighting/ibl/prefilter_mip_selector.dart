import 'dart:math' as math;

/// Maps material roughness to the appropriate mip level for the prefiltered
/// environment cubemap. Keeps the logic shared between CPU sampling paths and
/// GPU pipelines to ensure consistent results across platforms.
///
/// Roughness values are clamped to the [0, 1] range before conversion. The
/// mapping follows the common GGX recommendation of squaring the roughness
/// value to provide more precision for low-roughness highlights, then scaling
/// against the available mip range.
abstract class PrefilterMipSelector {
  /// Converts a roughness value in [0, 1] to a fractional mip level within
  /// `[0, mipCount - 1]`. Returns 0.0 when the cubemap does not expose any mips.
  ///
  /// [roughness] Material roughness in [0, 1].
  /// [mipCount] Total number of mip levels generated for the cube map.
  static double roughnessToMipLevel(double roughness, int mipCount) {
    final int clampedMipCount = math.max(1, mipCount);
    if (clampedMipCount <= 1) return 0.0;

    final double clampedRoughness = clamp01(roughness);
    final double perceptual = clampedRoughness * clampedRoughness;
    final double maxLevel = (clampedMipCount - 1).toDouble();
    
    return math.min(maxLevel, perceptual * maxLevel);
  }

  /// Utility used by tests and GPU uniform preparation to keep the clamp
  /// logic symmetric between CPU and shader code.
  static double clamp01(double value) => value.clamp(0.0, 1.0);
}
