import '../vector/index.dart';

/// Primary reference:
///   https://graphics.stanford.edu/papers/envmap/envmap.pdf
///
/// Secondary reference:
///   https://www.ppsloan.org/publications/StupidSH36.pdf

// 3-band SH defined by 9 coefficients

/// Represents a third-order spherical harmonics (SH). Light probes use this
/// class to encode lighting information.
class SphericalHarmonics3 {
  String type = "SphericalHarmonics3";

  List<Vector3> coefficients = [];

  SphericalHarmonics3() {
    for (int i = 0; i < 9; i++) {
      coefficients.add(Vector3.zero());
    }
  }

  /// [coefficients] - An array of SH coefficients.
  /// 
  /// Sets the given SH coefficients to this instance.
  SphericalHarmonics3 set(List<Vector3> coefficients) {
    for (int i = 0; i < 9; i++) {
      this.coefficients[i].setFrom(coefficients[i]);
    }

    return this;
  }

  /// Sets all SH coefficients to `0`.
  SphericalHarmonics3 zero() {
    for (int i = 0; i < 9; i++) {
      coefficients[i].setValues(0, 0, 0);
    }

    return this;
  }

  // get the radiance in the direction of the normal
  // target is a Vector3
  Vector3 getAt(Vector3 normal, Vector3 target) {
    // normal is assumed to be unit length

    final x = normal.x, y = normal.y, z = normal.z;

    final coeff = coefficients;

    // band 0
    target..setFrom(coeff[0])..scale(0.282095);

    // band 1
    target.addScaled(coeff[1], 0.488603 * y);
    target.addScaled(coeff[2], 0.488603 * z);
    target.addScaled(coeff[3], 0.488603 * x);

    // band 2
    target.addScaled(coeff[4], 1.092548 * (x * y));
    target.addScaled(coeff[5], 1.092548 * (y * z));
    target.addScaled(coeff[6], 0.315392 * (3.0 * z * z - 1.0));
    target.addScaled(coeff[7], 1.092548 * (x * z));
    target.addScaled(coeff[8], 0.546274 * (x * x - y * y));

    return target;
  }

  // get the irradiance (radiance convolved with cosine lobe) in the direction of the normal
  // target is a Vector3
  // https://graphics.stanford.edu/papers/envmap/envmap.pdf
  Vector3 getIrradianceAt(Vector3 normal, Vector3 target) {
    // normal is assumed to be unit length

    final x = normal.x, y = normal.y, z = normal.z;

    final coeff = coefficients;

    // band 0
    target..setFrom(coeff[0])..scale(0.886227); // π * 0.282095

    // band 1
    target.addScaled(
        coeff[1], 2.0 * 0.511664 * y); // ( 2 * π / 3 ) * 0.488603
    target.addScaled(coeff[2], 2.0 * 0.511664 * z);
    target.addScaled(coeff[3], 2.0 * 0.511664 * x);

    // band 2
    target.addScaled(
        coeff[4], 2.0 * 0.429043 * x * y); // ( π / 4 ) * 1.092548
    target.addScaled(coeff[5], 2.0 * 0.429043 * y * z);
    target.addScaled(
        coeff[6], 0.743125 * z * z - 0.247708); // ( π / 4 ) * 0.315392 * 3
    target.addScaled(coeff[7], 2.0 * 0.429043 * x * z);
    target.addScaled(
        coeff[8], 0.429043 * (x * x - y * y)); // ( π / 4 ) * 0.546274

    return target;
  }

  /// [sh] - The SH to add.
  /// 
  /// Adds the given SH to this instance.
  SphericalHarmonics3 add(SphericalHarmonics3 sh) {
    for (int i = 0; i < 9; i++) {
      coefficients[i].add(sh.coefficients[i]);
    }

    return this;
  }

  /// [sh] - The SH to add.
  /// 
  /// [s] - The scale factor.
  /// 
  /// A convenience method for performing [add] and [scale] at
  /// once.
  SphericalHarmonics3 addScaledSH(SphericalHarmonics3 sh, double s) {
    for (int i = 0; i < 9; i++) {
      coefficients[i].addScaled(sh.coefficients[i], s);
    }

    return this;
  }

  /// [s] - The scale factor.
  /// 
  /// Scales this SH by the given scale factor.
  SphericalHarmonics3 scale(double s) {
    for (int i = 0; i < 9; i++) {
      coefficients[i].scale(s);
    }

    return this;
  }

  /// [sh] - The SH to interpolate with.
  /// 
  /// [alpha] - The alpha factor.
  /// 
  /// Linear interpolates between the given SH and this instance by the given
  /// alpha factor.
  SphericalHarmonics3 lerp(SphericalHarmonics3 sh, double alpha) {
    for (int i = 0; i < 9; i++) {
      coefficients[i].lerp(sh.coefficients[i], alpha);
    }

    return this;
  }

  bool equals(SphericalHarmonics3 sh) {
    for (int i = 0; i < 9; i++) {
      if (!coefficients[i].equals(sh.coefficients[i])) {
        return false;
      }
    }

    return true;
  }

  /// [sh] - The SH to copy.
  /// 
  /// Copies the given SH to this instance.
  SphericalHarmonics3 copy(SphericalHarmonics3 sh) {
    return set(sh.coefficients);
  }

  /// Returns a new instance of [SphericalHarmonics3] with equal coefficients.
  SphericalHarmonics3 clone() {
    return SphericalHarmonics3().copy(this);
  }

  /// [array] - The array holding the numbers of the SH
  /// coefficients.
  /// 
  /// [offset] - (optional) The array offset.
  /// 
  /// Sets the coefficients of this instance from the given array.
  SphericalHarmonics3 fromArray(List<double> array, [int offset = 0]) {
    final coefficients = this.coefficients;

    for (int i = 0; i < 9; i++) {
      coefficients[i].copyFromArray(array, offset + (i * 3));
    }

    return this;
  }

  /// [array] - (optional) The target array.
  /// 
  /// [offset] - (optional) The array offset.
  /// 
  /// Returns an array with the coefficients, or copies them into the provided
  /// array. The coefficients are represented as numbers.
  List<double> toArray(List<double> array, [int offset = 0]) {
    final coefficients = this.coefficients;

    for (int i = 0; i < 9; i++) {
      coefficients[i].copyIntoArray(array, offset + (i * 3));
    }

    return array;
  }

  /// [normal] - The normal vector (assumed to be unit length).
  /// 
  /// [shBasis] - The resulting SH basis.
  /// 
  /// Computes the SH basis for the given normal vector.
  static void getBasisAt(Vector3 normal, List<double> shBasis) {
    // normal is assumed to be unit length

    final x = normal.x, y = normal.y, z = normal.z;

    // band 0
    shBasis[0] = 0.282095;

    // band 1
    shBasis[1] = 0.488603 * y;
    shBasis[2] = 0.488603 * z;
    shBasis[3] = 0.488603 * x;

    // band 2
    shBasis[4] = 1.092548 * x * y;
    shBasis[5] = 1.092548 * y * z;
    shBasis[6] = 0.315392 * (3 * z * z - 1);
    shBasis[7] = 1.092548 * x * z;
    shBasis[8] = 0.546274 * (x * x - y * y);
  }
}
