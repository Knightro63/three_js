import 'path.dart';
import 'package:three_js_math/three_js_math.dart';

/// Defines an arbitrary 2d shape plane using paths with optional holes. It
/// can be used with [ExtrudeGeometry], [ShapeGeometry], to get
/// points, or to get triangulated faces.
/// 
/// ```
/// final heartShape = Shape();

/// heartShape.moveTo( 25, 25 );
/// heartShape.bezierCurveTo( 25, 25, 20, 0, 0, 0 );
/// heartShape.bezierCurveTo( - 30, 0, - 30, 35, - 30, 35 );
/// heartShape.bezierCurveTo( - 30, 55, - 10, 77, 25, 95 );
/// heartShape.bezierCurveTo( 60, 77, 80, 55, 80, 35 );
/// heartShape.bezierCurveTo( 80, 35, 80, 0, 50, 0 );
/// heartShape.bezierCurveTo( 35, 0, 25, 25, 25, 25 );
/// 
/// final extrudeSettings = { 
///   'depth': 8, 
///   'bevelEnabled': true, 
///   'bevelSegments': 2, 
///   'steps': 2, 
///   'bevelSize': 1, 
///   'bevelThickness': 1 
/// };
/// 
/// final geometry = ExtrudeGeometry( heartShape, extrudeSettings );
/// 
/// final mesh = Mesh( geometry, MeshPhongMaterial() );
///```
class Shape extends Path {
  late String uuid;
  late List<Path> holes;

  /// [points] -- (optional) array of [Vector2].
  /// 
  /// Creates a Shape from the points. The first point defines the offset, then
  /// successive points are added to the [curves] array as
  /// [LineCurves].
  /// 
  /// If no points are specified, an empty shape is created and the
  /// [currentPoint] is set to the origin.
  Shape([super.points]){
    uuid = MathUtils.generateUUID();
    holes = [];
  }

  Shape.fromJson(Map<String, dynamic> json):super.fromJson(json) {
    uuid = json["uuid"];
    holes = [];

    for (int i = 0, l = json["holes"].length; i < l; i++) {
      final hole = json["holes"][i];
      holes.add(Path.fromJson(hole));
    }
  }

  /// [divisions] -- The fineness of the result.
  /// 
  /// Get an array of [Vector2] that represent the holes in the
  /// shape.
  List<List<Vector?>?> getPointsHoles(int divisions) {
    final holesPts = List<List<Vector?>?>.filled(holes.length, null);

    for (int i = 0, l = holes.length; i < l; i++) {
      holesPts[i] = holes[i].getPoints(divisions);
    }

    return holesPts;
  }

  /// [divisions] -- The fineness of the result.
  /// 
  /// Call [getPoints] on the shape and the [holes]
  /// array, and return an object of the form:
  ///
  /// where shape and holes are arrays of [Vector2].
  Map<String, dynamic> extractPoints(divisions) {
    return {
      "shape": getPoints(divisions),
      "holes": getPointsHoles(divisions)
    };
  }

  @override
  Shape copy(source){
    if(source is Shape){
      super.copy(source);

      holes = [];
      for (int i = 0, l = source.holes.length; i < l; i++) {
        final hole = source.holes[i];
        holes.add(hole.clone() as Shape);
      }
    }

    return this;
  }

  @override
   Map<String,dynamic> toJson() {
    Map<String,dynamic> data = super.toJson();

    data["uuid"] = uuid;
    data["holes"] = [];

    for (int i = 0, l = holes.length; i < l; i++) {
      final hole = holes[i];
      data["holes"].add(hole.toJson());
    }

    return data;
  }

  @override
  Shape fromJson(Map<String,dynamic> json) {
    super.fromJson(json);

    uuid = json['uuid'];
    holes = [];

    for (int i = 0, l = json['holes'].length; i < l; i++) {
      final hole = json['holes'][i];
      holes.add(Path(null).fromJson(hole));
    }

    return this;
  }
  @override
  Shape moveTo(double x, double y) {
    super.moveTo(x, y);
    return this;
  }
  @override
  Shape lineTo(double x, double y) {
    super.lineTo(x, y);
    return this;
  }
  @override
  Shape absarc(double aX, double aY, double aRadius, double aStartAngle, double aEndAngle, [bool? aClockwise]) {
    super.absarc(aX, aY, aRadius, aStartAngle, aEndAngle, aClockwise);
    return this;
  }
  @override
  Shape quadraticCurveTo(double aCPx, double aCPy, double aX, double aY) {
    super.quadraticCurveTo(aCPx, aCPy, aX, aY);
    return this;
  }
  @override
  Shape bezierCurveTo(double aCP1x, double aCP1y, double aCP2x, double aCP2y, double aX, double aY) {
    super.bezierCurveTo(aCP1x, aCP1y, aCP2x, aCP2y, aX, aY);
    return this;
  }
  @override
  Shape splineThru(List<Vector2> pts) {
    super.splineThru(pts);
    return this;
  }
  @override
  Shape arc(double aX, double aY, double aRadius, double aStartAngle, double aEndAngle, [bool? aClockwise]) {
    super.arc(aX, aY, aRadius, aStartAngle, aEndAngle, aClockwise);
    return this;
  }
  @override
  Shape ellipse(double aX, double aY, double xRadius, double yRadius, double aStartAngle, double aEndAngle, [bool? aClockwise, double? aRotation]) {
    super.ellipse(aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation);
    return this;
  }
  @override
  Shape absellipse(double aX, double aY, double xRadius, double yRadius, double aStartAngle, double aEndAngle, [bool? aClockwise, double? aRotation]) {
    super.absellipse(aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation);
    return this;
  }
}
