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
    if(constraint.coincidentTo != null){
      position.setFrom(constraint.coincidentTo!.position);
    }
    else if(constraint.verticalTo != null){
      // double length = position.distanceTo(constraint.verticalTo!.position);
      // final forwardVector = Vector3();
      // camera!.getWorldDirection(forwardVector);
      // final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);

      // position.setFrom(this.position).add(upVector.clone());//.scale(0.1);
    }
    else if(constraint.horizontalTo != null){
      //double length = position.distanceTo(constraint.horizontalTo!.position);
      // final forwardVector = Vector3();
      // final rightVector = Vector3();
      // camera!.getWorldDirection(forwardVector);
      // rightVector.cross2(camera.up, forwardVector).normalize();

      // position.setFrom(constraint.horizontalTo!.position).add(rightVector.clone());//.scale(length));
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