import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_js/three_js.dart';
import '../draw_types.dart';

class SketchPoint extends Mesh{
  SketchPoint([BufferGeometry? geometry, Material? material]):super(geometry,material);

  PointConstraint get constraint => userData['constraints'];

  List<ObjectConstraint> getConstraints(){
    return [constraint];
  }

  void updateConstraint([Camera? camera]){
    final upVector = Vector3(0, 1, 0).applyQuaternion(camera!.quaternion);

    if(constraint.coincidentTo != null){
      position.setFrom(constraint.coincidentTo!.position);
    }
    else if(constraint.verticalTo != null){
      final s1 = Plane().setFromNormalAndCoplanarPoint(upVector, constraint.verticalTo!.position).distanceToPoint(this.position);
      print(constraint.verticalTo!.position);
      position.setFrom(Vector3(0.1,0.1,0.1));//.add(upVector.clone().scale(s1));//.setFrom(constraint.verticalTo!.position)
    }
    else if(constraint.horizontalTo != null){
      final forwardVector = Vector3();
      final rightVector = Vector3();
      camera.getWorldDirection(forwardVector);
      rightVector.cross2(upVector, forwardVector).normalize();

      final s2 = Plane().setFromNormalAndCoplanarPoint(rightVector, constraint.horizontalTo!.position).distanceToPoint(this.position);
      position.setFrom(constraint.horizontalTo!.position).add(rightVector.clone().scale(s2));
    }
  }

  void addConstraint(Constraints constraint,[Object3D? object]){
    switch (constraint) {
      case Constraints.horizontal:
        this.constraint.horizontalTo = object as SketchPoint;
        break;
      case Constraints.vertical:
        this.constraint.verticalTo = object as SketchPoint;
        break;
      case Constraints.midpoint:
        this.constraint.midpointTo = object as SketchPoint;
        break;
      case Constraints.coincident:
        this.constraint.coincidentTo = object as SketchPoint;
        break;
      default:
    }
  }
}