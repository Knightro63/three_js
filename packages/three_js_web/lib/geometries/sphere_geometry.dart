import '../core/index.dart';
import 'dart:js_interop';
import 'dart:math' as math;

@JS('PlaneGeometry')
class SphereGeometry extends BufferGeometry {
  external SphereGeometry([
    double radius = 1,
    int widthSegments = 32,
    int heightSegments = 16,
    double phiStart = 0,
    double phiLength = math.pi * 2,
    double thetaStart = 0,
    double thetaLength = math.pi
  ]);

  static fromJson(data) {
    return SphereGeometry(
        data["radius"],
        data["widthSegments"],
        data["heightSegments"],
        data["phiStart"],
        data["phiLength"],
        data["thetaStart"],
        data["thetaLength"]);
  }
}
