import 'cylinder.dart';
import 'dart:math' as math;

/// A class for generating cone geometries.
/// ```
/// final geometry = ConeGeometry( 5, 20, 32 ); 
/// final material = MeshBasicMaterial( { MaterialProperty.color: 0xffff00}); 
/// final circle = Mesh(geometry, material); 
/// scene.add(circle);
/// ```
class ConeGeometry extends CylinderGeometry {
  /// [radius] — Radius of the cone base. Default is `1`.
  /// 
  /// [height] — Height of the cone. Default is `1`.
  /// 
  /// [radialSegments] — Number of segmented faces around the circumference of the
  /// cone. Default is `32`
  /// 
  /// [heightSegments] — Number of rows of faces along the height of the cone.
  /// Default is `1`.
  /// 
  /// [openEnded] — A Boolean indicating whether the base of the cone is open or
  /// capped. Default is false, meaning capped.
  /// 
  /// [thetaStart] — Start angle for first segment, default = 0 (three o'clock
  /// position).
  /// 
  /// [thetaLength] — The central angle, often called theta, of the circular
  /// sector. The default is `2`*Pi, which makes for a complete cone.
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
