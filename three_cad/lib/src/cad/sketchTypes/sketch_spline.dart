import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_js/three_js.dart';
import '../draw_types.dart';

class SketchSpline extends SketchObjects{
  SketchSpline():super();

  @override
  List<ObjectConstraint> getConstraints(){
    final List<PointConstraint> points = [];
    for(int i = 1; i < children.length;i++){
      points.add(children[i].userData['constraints']);
    }
    return points;
  }

  @override
  void addConstraint(Constraints constraint,[Object3D? object]){}

  @override
  void updateConstraint(){}

  @override
  void redraw(){
    DrawType.updateSplineOutline(getLine()!, getPointsPositions()!);
  }
}