import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_point.dart';
import 'package:three_js/three_js.dart';
import 'dart:math' as math;
import '../draw_types.dart';

class SketchCircle extends SketchObjects{
  Camera camera;
  bool allowRedraw = true;

  SketchCircle(this.camera):super();

  SketchPoint get center => children.last as SketchPoint;
  Vector3 get centerPosition => children.last.position;
  PointConstraint get centerConstraint => children.last.userData['constraints'];
  CircleConstraint get circleConstraint => children[0].userData['constraints'];
  double get diameter => circleConstraint.diameter ?? _getDiameter();

  double _getDiameter(){
    final p1 = centerPosition;
    final position = getLine()!.geometry!.attributes['position'] as Float32BufferAttribute;
    return p1.distanceTo(Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble()));
  }

  @override
  List<ObjectConstraint> getConstraints(){
    return [centerConstraint,circleConstraint];
  }

  void updateDiameter(Vector3 point){
    final center = centerPosition.clone();

    final forwardVector = Vector3();
    final rightVector = Vector3();
    camera.getWorldDirection(forwardVector);
    rightVector.cross2(camera.up, forwardVector).normalize();
    final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);

    final s1 = Plane().setFromNormalAndCoplanarPoint(upVector, center).distanceToPoint(point);
    final s2 = Plane().setFromNormalAndCoplanarPoint(rightVector, center).distanceToPoint(point);

    final s = math.max(s1.abs(),s2.abs());

    final p1 = center.clone().add(upVector.clone().scale(-s));
    final p2 = center.clone().add(rightVector.clone().scale(s));
    final p3 = center.clone().add(upVector.clone().scale(s));
    final p4 = center.clone().add(rightVector.clone().scale(-s));

    DrawType.updateSplineOutline(getLine()!, [p1,p2,p3,p4], true, 64);

    allowRedraw = false;
  }

  @override
  void addConstraint(Constraints constraint,[Object3D? object]){
    switch (constraint) {
      case Constraints.concentric:
        circleConstraint.concentricTo = object as SketchCircle;
        break;
      case Constraints.equal:
        circleConstraint.equalTo = object as SketchCircle;
        break;
      case Constraints.coincident:
        centerConstraint.coincidentTo = object as SketchPoint;
        break;
      default:
    }
  }

  @override
  void updateConstraint(){
    if(circleConstraint.concentricTo != null){
      final c1 = this;
      final c2 = circleConstraint.concentricTo!;

      final center = c2.children.last.position.clone();
      final dist = diameter;

      final forwardVector = Vector3();
      final rightVector = Vector3();
      camera.getWorldDirection(forwardVector);
      rightVector.cross2(camera.up, forwardVector).normalize();
      final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);

      final p1 = center.clone().add(upVector.clone().scale(-dist));
      final p2 = center.clone().add(rightVector.clone().scale(dist));
      final p3 = center.clone().add(upVector.clone().scale(dist));
      final p4 = center.clone().add(rightVector.clone().scale(-dist));

      c1.children.last.position.setFrom(center);

      DrawType.updateSplineOutline(c1.children.first as dynamic, [p1,p2,p3,p4], true, 64);
    }
    else if(circleConstraint.equalTo != null){
      final c2 = this;
      final center = c2.children.last.position.clone();

      final double dist = circleConstraint.diameter ?? circleConstraint.equalTo!.diameter;

      final forwardVector = Vector3();
      final rightVector = Vector3();
      camera.getWorldDirection(forwardVector);
      rightVector.cross2(camera.up, forwardVector).normalize();
      final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);

      final p1 = center.clone().add(upVector.clone().scale(-dist));
      final p2 = center.clone().add(rightVector.clone().scale(dist));
      final p3 = center.clone().add(upVector.clone().scale(dist));
      final p4 = center.clone().add(rightVector.clone().scale(-dist));

      c2.children.last.position.setFrom(center);

      DrawType.updateSplineOutline(c2.children.first as dynamic, [p1,p2,p3,p4], true, 64);
    }
  }

  @override
  void redraw(){
    if(!allowRedraw){
      allowRedraw = true;
      return;
    }
    final dia = diameter;
    final center = this.center.position;

    final forwardVector = Vector3();
    final rightVector = Vector3();
    camera.getWorldDirection(forwardVector);
    rightVector.cross2(camera.up, forwardVector).normalize();
    final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);

    final p1 = center.clone().add(upVector.clone().scale(-dia));
    final p2 = center.clone().add(rightVector.clone().scale(dia));
    final p3 = center.clone().add(upVector.clone().scale(dia));
    final p4 = center.clone().add(rightVector.clone().scale(-dia));

    DrawType.updateSplineOutline(getLine()!, [p1,p2,p3,p4], true, 64);
  }
  void redrawCircleFromCenter(Camera camera, Vector3 center, double diameter){
    centerPosition.setFrom(center);

    final forwardVector = Vector3();
    final rightVector = Vector3();
    camera.getWorldDirection(forwardVector);
    rightVector.cross2(camera.up, forwardVector).normalize();
    final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);

    final p1 = center.clone().add(upVector.clone().scale(-diameter));
    final p2 = center.clone().add(rightVector.clone().scale(diameter));
    final p3 = center.clone().add(upVector.clone().scale(diameter));
    final p4 = center.clone().add(rightVector.clone().scale(-diameter));

    DrawType.updateSplineOutline(getLine()!, [p1,p2,p3,p4], true, 64);
  }
}