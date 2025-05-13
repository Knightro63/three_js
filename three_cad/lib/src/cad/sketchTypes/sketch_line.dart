import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_cad/src/cad/draw_types.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_circle.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_point.dart';
import 'package:three_js/three_js.dart';
import 'package:three_js_line/three_js_line.dart';
//import 'dart:math' as math;

class SketchLine extends SketchObjects{
  SketchLine(this.camera):super();

  Camera camera;
  SketchPoint get point1 => children[1] as SketchPoint;
  SketchPoint get point2 => children[2] as SketchPoint;
  Vector3 get point1Position => children[1].position;
  Vector3 get point2Position => children[2].position;

  LineConstraint get lineConstraint {
    return children[0].userData['constraints'];
  }

  PointConstraint get point1Constraint {
    return children[1].userData['constraints'];
  }

  PointConstraint get point2Constraint {
    return children[2].userData['constraints'];
  }

  @override
  List<ObjectConstraint> getConstraints(){
    return [lineConstraint,point1Constraint,point2Constraint];
  }

  @override
  void addConstraint(Constraints constraint,[Object3D? object]){
    switch (constraint) {
      case Constraints.vertical:
        point1Constraint.verticalTo = point2 as SketchPoint;
        break;
      case Constraints.horizontal:
        point1Constraint.horizontalTo = point2 as SketchPoint;
        break;
      case Constraints.midpoint:
        lineConstraint.midpointTo = object as SketchLine;
        break;
      case Constraints.parallel:
        lineConstraint.parallelTo = object as SketchLine;
        break;
      case Constraints.perpendicular:
        lineConstraint.perpendicularTo = object as SketchLine;
        break;
      case Constraints.colinear:
        lineConstraint.colinearTo = object as SketchLine;
        break;
      case Constraints.tangent:
        lineConstraint.tangentTo = object as SketchCircle;
        break;
      case Constraints.equal:
        lineConstraint.equalTo = object as SketchLine;
        break;
      default:
    }
  }

  void createHVConstraint(){
    final constraints = lineConstraint;
    if(constraints.isVertical){
      point1Constraint.verticalTo = point2;
    }
    else if(constraints.isHorizontal){
      point1Constraint.horizontalTo = point2;
    }
  }

  @override
  void updateConstraint(){
    point1.updateConstraint(camera);
    point2.updateConstraint(camera);

    final constraints = lineConstraint;
    double length = point1Position.distanceTo(point2Position);

    if(lineConstraint.equalTo != null){
      length =  constraints.length ?? lineConstraint.equalTo!.point1Position.distanceTo(lineConstraint.equalTo!.point2Position);
    }

    if(constraints.parallelTo != null){

    }

    if(constraints.perpendicularTo != null){

    }

    if(constraints.colinearTo != null){

    }

    if(constraints.midpointTo != null){

    }

    if(constraints.tangentTo != null){

    }
  }

  void updatePosition(Vector3 position){

  }
  void updateLength(Vector3 point){
    point2Position.setFrom(point);
  }

  @override
  void redraw(){
    final p1 = point1Position;
    final p2 = point2Position;

    _redrawLineFromPoints(getLine()!.geometry!, p1, p2);
    if(getLine()!.children[0] is Line2){
      _redrawLFatineFromPoints(getLine()!.children[0].geometry!, p1, p2);
      (getLine()!.children[0] as Line2).computeLineDistances();
    }
  }
  void _redrawLFatineFromPoints(BufferGeometry geometry, Vector3 p1, Vector3 p2){
    geometry.attributes["instanceStart"].array[0] = p1.x;
    geometry.attributes["instanceStart"].array[1] = p1.y;
    geometry.attributes["instanceStart"].array[2] = p1.z;
    geometry.attributes["instanceStart"].array[3] = p2.x;
    geometry.attributes["instanceStart"].array[4] = p2.y;
    geometry.attributes["instanceStart"].array[5] = p2.z;

    geometry.attributes["instanceStart"].needsUpdate = true;
  }
  void _redrawLineFromPoints(BufferGeometry geometry, Vector3 p1, Vector3 p2){
    geometry.attributes["position"].array[0] = p1.x;
    geometry.attributes["position"].array[1] = p1.y;
    geometry.attributes["position"].array[2] = p1.z;
    geometry.attributes["position"].array[3] = p2.x;
    geometry.attributes["position"].array[4] = p2.y;
    geometry.attributes["position"].array[5] = p2.z;

    geometry.attributes["position"].needsUpdate = true;
    geometry.computeBoundingSphere();
    geometry.computeBoundingBox();
  }
  
}