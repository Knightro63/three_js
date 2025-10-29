/*
 * Ref: https://en.wikipedia.org/wiki/Spherical_coordinate_system
 *
 * The polar angle (phi) is measured from the positive y-axis. The positive y-axis is up.
 * The azimuthal angle (theta) is measured from the positive z-axis.
 */

import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

/// A point's [spherical coordinates](https://en.wikipedia.org/wiki/Spherical_coordinate_system).
class Spherical {
  late double radius;
  late double phi;
  late double theta;

  /// [radius] - the radius, or the
  /// [Euclidean distance](https://en.wikipedia.org/wiki/Euclidean_distance)
  /// (straight-line distance) from the point to the origin. Default is
  /// `1.0`.
  /// 
  /// [phi] - polar angle in radians from the y (up) axis. Default is
  /// `0`.
  /// 
  /// [theta] - equator angle in radians around the y (up) axis.
  /// Default is `0`.
  /// 
  /// The poles (phi) are at the positive and negative y axis. The equator
  /// (theta) starts at positive z.
  Spherical({this.radius = 1, this.phi = 0, this.theta = 0});

  Spherical set(double radius, double phi, double theta) {
    this.radius = radius;
    this.phi = phi;
    this.theta = theta;

    return this;
  }

  /// Returns a new spherical with the same [radius], [phi] 
  /// and [theta] properties as this one.
  Spherical clone() {
    return Spherical()..copy(this);
  }

  /// Copies the values of the passed Spherical's [radius],
  /// [phi] and [theta] properties to this spherical.
  Spherical copy(Spherical other) {
    radius = other.radius;
    phi = other.phi;
    theta = other.theta;

    return this;
  }

  /// Restricts the polar angle [phi] to be between 0.000001 and pi -
  /// 0.000001.
  Spherical makeSafe() {
    const eps = 0.000001;
    phi = math.max(eps, math.min(math.pi - eps, phi)).toDouble();

    return this;
  }

  /// Sets values of this spherical's [radius], [phi] and
  /// [theta] properties from the [Vector3].
  Spherical setFromVector3(Vector3 v) {
    return setFromCartesianCoords(v.x, v.y, v.z);
  }

  /// Sets values of this spherical's [radius], [phi] and
  /// [theta] properties from Cartesian coordinates.
  Spherical setFromCartesianCoords(double x, double y, double z) {
    radius = math.sqrt(x * x + y * y + z * z);

    if (radius == 0) {
      theta = 0;
      phi = 0;
    } else {
      theta = math.atan2(x, z);
      phi = math.acos(MathUtils.clamp(y / radius, -1, 1));
    }

    return this;
  }
}
