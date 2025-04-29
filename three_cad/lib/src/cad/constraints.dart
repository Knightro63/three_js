import 'package:three_js/three_js.dart';

enum Constraints{
  none,
  coincident,
  vertical,
  horizontal,
  parallel,
  perpendicular,
  tangent,
  equal,
  midpoint,
  concentric,
}

class ObjectConstraint{
  double? diameter;
  double? length;

  bool isHorizontal = false;
  bool isVertical = false;
  bool isHypotenuse = false;

  Object3D? hypotenuseTo;
  Object3D? distanceTo;

  Object3D? horizontalTo;
  Object3D? verticalTo;
  Object3D? midpointTo;
  Object3D? coincidentTo;
  Object3D? concentric;
  Object3D? equal;
  Object3D? tangent;
  Object3D? perpendicular;
  Object3D? parallel;

  bool get isFixed => _isFixed();
  bool _isFixed(){
    return false;
  }
}