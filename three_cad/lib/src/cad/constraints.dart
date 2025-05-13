import 'package:three_cad/src/cad/sketchTypes/sketch_circle.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_line.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_point.dart';
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
  colinear
}

class ObjectConstraint{
  Object3D? distanceTo;
  bool _update = false;

  bool get isFixed => _isFixed();
  bool _isFixed(){
    return false;
  }

  bool allowed(Constraints constraint){
    throw{'this has not been implimented'};
  }

  bool get hasConstraint => distanceTo != null;
  
  void updated(){
    _update = false;
  }
}

class PointConstraint extends ObjectConstraint{
  SketchPoint? _horizontalTo;
  SketchPoint? _verticalTo;
  SketchPoint? _midpointTo;
  SketchPoint? _coincidentTo;

  SketchPoint? get horizontalTo => _horizontalTo;
  SketchPoint? get verticalTo => _verticalTo;
  SketchPoint? get midpointTo => _midpointTo;
  SketchPoint? get coincidentTo => _coincidentTo;

  set horizontalTo(SketchPoint? o){
    _horizontalTo = o;
    _update = true;
  }
  set verticalTo(SketchPoint? o){
    _verticalTo = o;
    _update = true;
  }
  set midpointTo(SketchPoint? o){
    _midpointTo = o;
    _update = true;
  }
  set coincidentTo(SketchPoint? o){
    _coincidentTo = o;
    _update = true;
  }

  @override
  bool allowed(Constraints constraint){
    return 
      constraint == Constraints.horizontal || 
      constraint == Constraints.vertical || 
      constraint == Constraints.coincident || 
      constraint == Constraints.midpoint;
  }

  bool get hasConstraint => 
    distanceTo != null ||
    horizontalTo != null || 
    verticalTo != null || 
    midpointTo != null || 
    coincidentTo != null;
}

class LineConstraint extends ObjectConstraint{
  double? _length;
  double? get length => equalTo?.lineConstraint.length ?? _length;
  set length(double? len){
    _length = len;
  }
  bool isHorizontal = false;
  bool isVertical = false;

  SketchLine? perpendicularTo;
  SketchLine? parallelTo;
  SketchLine? colinearTo;
  SketchLine? midpointTo;
  SketchCircle? tangentTo;
  SketchLine? equalTo;

  @override
  bool allowed(Constraints constraint){
    return 
      constraint == Constraints.horizontal || 
      constraint == Constraints.vertical || 
      constraint == Constraints.midpoint ||
      constraint == Constraints.parallel || 
      constraint == Constraints.perpendicular ||
      constraint == Constraints.tangent || 
      constraint == Constraints.colinear;
  }

  bool get hasConstraint =>
    isHorizontal ||
    isVertical ||
    distanceTo != null ||
    length != null || 
    perpendicularTo != null || 
    midpointTo != null || 
    parallelTo != null ||
    colinearTo != null || 
    tangentTo != null ||
    equalTo != null;
}

class CircleConstraint extends ObjectConstraint{
  double? tempDia;
  double? _diameter;
  double? get diameter => equalTo?.circleConstraint.diameter ?? _diameter ?? tempDia;
  set diameter(double? dia){
    _diameter = dia;
  }
  SketchCircle? equalTo;
  SketchCircle? concentricTo;

  @override
  bool allowed(Constraints constraint){
    return constraint == Constraints.concentric;
  }

  bool get hasConstraint => 
    distanceTo != null ||
    diameter != null || 
    equalTo != null || 
    concentricTo != null;
}