/*
 * Ref: https://en.wikipedia.org/wiki/Spherical_coordinate_system
 *
 * The polar angle (phi) is measured from the positive y-axis. The positive y-axis is up.
 * The azimuthal angle (theta) is measured from the positive z-axis.
 */

import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

class Spherical {
  late double radius;
  late double phi;
  late double theta;

  Spherical({this.radius = 1, this.phi = 0, this.theta = 0});

  Spherical set(double radius, double phi, double theta) {
    this.radius = radius;
    this.phi = phi;
    this.theta = theta;

    return this;
  }

  Spherical clone() {
    return Spherical().copy(this);
  }

  Spherical copy(Spherical other) {
    radius = other.radius;
    phi = other.phi;
    theta = other.theta;

    return this;
  }

  // restrict phi to be betwee EPS and PI-EPS
  Spherical makeSafe() {
    const eps = 0.000001;
    phi = math.max(eps, math.min(math.pi - eps, phi)).toDouble();

    return this;
  }

  Spherical setFromVector3(Vector3 v) {
    return setFromCartesianCoords(v.x, v.y, v.z);
  }

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
