import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/// Result type for IBL operations using a compile-time exhaustive sealed hierarchy.
sealed class IBLResult<T> {
  const IBLResult();
}

class IBLSuccess<T> extends IBLResult<T> {
  const IBLSuccess(this.data);
  final T data;
}

class IBLError<T> extends IBLResult<T> {
  const IBLError(this.message);
  final String message;
}

/// HDR Environment data
class HDREnvironment {
  const HDREnvironment({
    required this.data,
    required this.width,
    required this.height,
  });

  final Float32List data;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HDREnvironment &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height &&
          // Content equality fallback instead of reference comparison
          _listEquals(data, other.data);

  @override
  int get hashCode => Object.hash(Object.hashAll(data), width, height);
}

/// IBL Configuration
class IBLConfig {
  const IBLConfig({
    this.irradianceSize = 32,
    this.prefilterSize = 128,
    this.brdfLutSize = 512,
    this.roughnessLevels = 5,
    this.samples = 1024,
  });

  final int irradianceSize;
  final int prefilterSize;
  final int brdfLutSize;
  final int roughnessLevels;
  final int samples;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IBLConfig &&
          runtimeType == other.runtimeType &&
          irradianceSize == other.irradianceSize &&
          prefilterSize == other.prefilterSize &&
          brdfLutSize == other.brdfLutSize &&
          roughnessLevels == other.roughnessLevels &&
          samples == other.samples;

  @override
  int get hashCode => Object.hash(irradianceSize, prefilterSize, brdfLutSize, roughnessLevels, samples);
}

/// IBL Environment Maps
class IBLEnvironmentMaps {
  const IBLEnvironmentMaps({
    required this.environment,
    required this.irradiance,
    required this.prefilter,
    required this.brdfLut,
  });

  final CubeTexture environment;
  final CubeTexture irradiance;
  final CubeTexture prefilter;
  final Texture brdfLut;
}

/// Spherical harmonics interface
abstract class SphericalHarmonics {
  List<Vector3> get coefficients;
  Vector3 evaluate(Vector3 direction);
}

/// Spherical harmonics implementation
class IBLSphericalHarmonics implements SphericalHarmonics {
  const IBLSphericalHarmonics({
    required this.coefficients,
  });

  @override
  final List<Vector3> coefficients;

  @override
  Vector3 evaluate(Vector3 direction) {
    final sh = _evaluateBasis(direction);
    var result = Vector3.zero(); // Assuming a static vector property exists
    
    for (int i = 0; i < 9; i++) {
      result = result.addScaled(coefficients[i], sh[i]);
    }
    return result;
  }

  Float32List _evaluateBasis(Vector3 direction) {
    final double x = direction.x;
    final double y = direction.y;
    final double z = direction.z;
    
    return Float32List.fromList([
      0.282095,
      0.488603 * y,
      0.488603 * z,
      0.488603 * x,
      1.092548 * (x * y),
      1.092548 * (y * z),
      0.315392 * (3.0 * z * z - 1.0),
      1.092548 * (x * z),
      0.546274 * (x * x - (y * y))
    ]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IBLSphericalHarmonics &&
          runtimeType == other.runtimeType &&
          _listEquals(coefficients, other.coefficients);

  @override
  int get hashCode => Object.hashAll(coefficients);
}

/// Specialized internal fast content equality helper for typed list checking.
bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
