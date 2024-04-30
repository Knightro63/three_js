import 'path.dart';
import 'package:three_js_math/three_js_math.dart';

class Shape extends Path {
  late String uuid;
  late List<Path> holes;

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

  List<List<Vector?>?> getPointsHoles(int divisions) {
    final holesPts = List<List<Vector?>?>.filled(holes.length, null);

    for (int i = 0, l = holes.length; i < l; i++) {
      holesPts[i] = holes[i].getPoints(divisions);
    }

    return holesPts;
  }

  // get points of shape and holes (keypoints based on segments parameter)

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
