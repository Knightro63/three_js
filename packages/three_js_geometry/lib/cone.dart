import 'cylinder.dart';
import 'dart:math' as math;

class ConeGeometry extends CylinderGeometry {
  ConeGeometry([
    double radius = 1,
    double height = 1,
    int radialSegments = 8,
    int heightSegments = 1,
    bool openEnded = false,
    double thetaStart = 0,
    double thetaLength = math.pi * 2
  ]):super(0, radius, height, radialSegments, heightSegments, openEnded,thetaStart, thetaLength) {
    type = 'ConeGeometry';
    parameters = {
      "radius": radius,
      "height": height,
      "radialSegments": radialSegments,
      "heightSegments": heightSegments,
      "openEnded": openEnded,
      "thetaStart": thetaStart,
      "thetaLength": thetaLength
    };
  }
}
