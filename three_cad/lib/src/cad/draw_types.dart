import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_point.dart';
import 'package:three_cad/src/cad/sketchTypes/sketch_spline.dart';
import 'package:three_js/three_js.dart';
//import 'dart:math' as math;
import 'package:three_js_line/three_js_line.dart';
import 'sketchTypes/sketch_line.dart';
import 'sketchTypes/sketch_circle.dart';

class SketchObjects extends Object3D{
  Line? getLine(){
    if(name == 'line' || name == 'circleSpline' || name == 'spline'){
      return children.first as Line;
    }
    return null;
  }

  List<Object3D>? getPoints(){
    if(name == 'line' || name == 'spline'){
      return children.getRange(1, children.length).toList(); // TODO: -1
    }
    return null;
  }

  List<Vector3>? getPointsPositions(){
    if(name == 'line' || name == 'spline'){
      final List<Vector3> points = [];
      for(int i = 1; i < children.length;i++){
        points.add(children[i].position);
      }
      return points;
    }
    return null;
  }

  List<ObjectConstraint> getConstraints(){
    throw{'Not implimented on ${runtimeType}!'};
  }

  void redraw(){}
  void updateConstraint(){
    throw{'Not implimented on ${runtimeType}!'};
  }

  void addConstraint(Constraints constraint,[SketchObjects? object]){}
}


enum DrawType{
  none,
  dimensions,
  point,
  line,
  arc3Point,
  arcCenterPoint,
  circleCenter,
  spline,
  boxCenter,
  box2Point,
  circle2Point,
  box3Point,
  mirror,
  circularPatern,
  retangularPattern;
  
  static SketchSpline createSpline(Vector3 position, int color){
    final g = SketchSpline()..name = 'spline';
    final line = createNoPointsLine(position, color,200);
    g.add(line);
    g.add(creatPoint(position,color));
    g.add(creatPoint(position,color));

    updateSplineOutline(line, [position,position]);

    return g;
  }
  static SketchCircle createCircleSpline(Camera camera,Vector3 position, int color){
    SketchCircle objects = SketchCircle(camera)..name = 'circleSpline';
    final line = createNoPointsLine(position, color, 64);
    objects.add(line..userData['constraints'] = CircleConstraint());
    objects.add(creatPoint(position,color));

    updateSplineOutline(line, [position,position,position,position], true, 64);
    
    return objects;
  } 
  static void updateSplineOutline(Line mesh, List<Vector3> positions,[bool closed = false, int numLines = 200]){
    final point = Vector3();
    CatmullRomCurve3 curve = CatmullRomCurve3( points:positions );
    curve.curveType = 'catmullrom';
    curve.closed = closed;
    curve.tension = 0.8;

    final position = mesh.geometry!.attributes['position'];
    
    for (int i = 0; i < numLines; i ++ ) {
      final t = i / ( numLines - 1 );
      curve.getPoint( t, point );
      (position as Float32BufferAttribute).setXYZ( i, point.x, point.y, point.z );
    }

    position.needsUpdate = true;

    (mesh.children[0].geometry! as LineGeometry).fromLine(mesh);

    mesh.geometry?.computeBoundingSphere();
    mesh.geometry?.computeBoundingBox();
  }

  static List<SketchObjects> createBoxCenter(Camera camera, Vector3 position, int color){
    final line1 = createLine(camera,Vector3.copy(position),color); //p1,p2
    final line2 = createLine(camera,Vector3.copy(position),color); //p3,p4
    final line3 = createLine(camera,Vector3.copy(position),color); //p5,p6
    final line4 = createLine(camera,Vector3.copy(position),color); //p7,p8
    
    final line5 = createLine(camera,Vector3.copy(position),0xffff00);
    final line6 = createLine(camera,Vector3.copy(position),0xffff00);
    
    (line1.userData['constraints'] as LineConstraint).isVertical = true;
    (line1.children[1].userData['constraints'] as PointConstraint).coincidentTo = line2.children[0] as SketchPoint;

    (line2.userData['constraints'] as LineConstraint).isHorizontal = true;
    (line2.children[1].userData['constraints'] as PointConstraint).coincidentTo = line3.children[0] as SketchPoint;

    (line3.userData['constraints'] as LineConstraint).isVertical = true;
    (line3.children[1].userData['constraints'] as PointConstraint).coincidentTo = line4.children[0] as SketchPoint;

    (line4.userData['constraints'] as LineConstraint).isHorizontal = true;
    (line4.children[1].userData['constraints'] as PointConstraint).coincidentTo = line1.children[0] as SketchPoint;

    return [line1,line2,line3,line4,line5,line6];
  }

  static List<SketchObjects> createBox2Point(Camera camera, Vector3 position, int color){
    final line1 = createLine(camera,Vector3.copy(position),color); //p1,p2
    final line2 = createLine(camera,Vector3.copy(position),color); //p3,p4
    final line3 = createLine(camera,Vector3.copy(position),color); //p5,p6
    final line4 = createLine(camera,Vector3.copy(position),color); //p7,p8

    line1.lineConstraint.isHorizontal = true;
    line1.point2Constraint.coincidentTo = line2.point1;

    line2.lineConstraint.isVertical = true;
    line2.point2Constraint.coincidentTo = line3.point1;

    // line3.lineConstraint.isHorizontal = true;
    // line3.point2Constraint.coincidentTo = line4.point1;

    line4.lineConstraint.isVertical = true;
    line4.point2Constraint.coincidentTo = line1.point2;

    line1.createHVConstraint();
    line2.createHVConstraint();
    //line3.createHVConstraint();
    line4.createHVConstraint();

    return [line1,line2,line3,line4];
  }

  static SketchPoint creatPoint(Vector3 position, int color,[String name = 'point']){
    return SketchPoint(
        SphereGeometry(0.01,8,8),
        MeshBasicMaterial.fromMap({
          'color': color,
        })
      )
      ..userData['constraints'] = PointConstraint()
      ..name = name
      ..position.x = position.x
      ..position.y = position.y
      ..position.z = position.z;
  }

  static SketchLine createLine(Camera camera, Vector3 position, int color, [int segments = 0]){
    SketchLine objects = SketchLine(camera)..name = 'line';
    final line = createSLine(position, color, segments);
    line.add(createFatLine(position, color, line))
    ..userData['constraints'] = LineConstraint();
    objects.add(line);
    if(segments == 0){
      objects.addAll([creatPoint(position, color,'linePoint'),creatPoint(position, color,'linePoint')]);
    }
    return objects;
  }
  static Line createNoPointsLine(Vector3 position, int color, [int segments = 0]){
    final line = createSLine(position, color,segments);
    line.add(createFatLine(position, color, line));
    return line;
  }
  static Line2 createFatLine(Vector3 position, int color, Line line){
    final geometry = LineGeometry().fromLine(line);
    final constructionLine = LineMaterial.fromMap( {
      'color': 0xffff00,
      'linewidth': 2,
    })
    ..worldUnits = false
    ..alphaToCoverage = true
    ..dashScale = 10
    ..dashed = true;
    
    final matLine = LineMaterial.fromMap( {
      'color': color,
      'linewidth': 2, // in world units with size attenuation, pixels otherwise
    })
    ..worldUnits = false;

    return Line2( geometry, color == 0xffff00?constructionLine:matLine)
    ..name = 'line2'
    ..userData['construction'] = color == 0xffff00
    ..computeLineDistances();
  }

  static LineDashedMaterial constructionLine = LineDashedMaterial.fromMap( {
    'color': 0xffff00,
    'transparent': true,
    'opacity': 0.5,
    'linewidth': 5,
    'gapSize': 1,
    'dashSize': 0.5
  });
  static LineBasicMaterial matLine = LineBasicMaterial.fromMap( {
    'color': 0x000000,//construction?0xffff00:215910,
    'visible': false,
    'linewidth': 5
  });

  static Line createSLine(Vector3 position, int color, [int segments = 0]){
    final geometry = BufferGeometry();
    geometry.setAttributeFromString(
      'position',
      segments == 0?Float32BufferAttribute.fromList(position.storage+position.storage,3):Float32BufferAttribute( Float32Array( segments * 3 ), 3 )
    );

    return Line( geometry, matLine..color.setFromHex32(color))
    ..name = 'line'
    ..computeLineDistances()
    ..userData['construction'] = color == 0xffff00;
  }
}