import 'dart:math' as math;
import 'package:css/css.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as mat;
import 'package:three_cad/src/cad/constraints.dart';
import 'package:three_cad/src/cad/draw_types.dart';
import 'package:three_js/three_js.dart';
import 'package:three_js_line/three_js_line.dart';

extension on Color{
  mat.Color toFlutterColor(){
    return mat.Color(getHex());
  }

  Color darken([double amount = .1]) {
    return CSS.darken(toFlutterColor(),amount).toThreeColor();
  }

  Color lighten([double amount = .1]) {
    return CSS.lighten(toFlutterColor(),amount).toThreeColor();
  }
}

extension on mat.Color{
  Color toThreeColor(){
    return Color.fromHex64(toARGB32());
  }
}

class Sketch{
  Sketch(Object3D plane){
    meshPlane = Mesh(
      PlaneGeometry(10,10),
      MeshBasicMaterial.fromMap({
        'color':0xffffff, 
        'side': DoubleSide, 
        'transparent': true, 
        'opacity': 0
      })
    )
    ..name = 'SketchPlane'
    ..position.setFrom(plane.position)
    ..rotation.setFromRotationMatrix(plane.matrix);
  }

  late Mesh meshPlane;
  Group render = Group();
  List<Group> sketches = [];
  List<Object3D> scale = [];
  List<Object3D> toDispose = [];

  bool newSketch = false;
  bool newSketchDidStart = false;

  void dispose(){
    meshPlane.dispose();
    render.dispose();
    minorDispose();
  }

  Object3D? get currentSketchPart => _getCurrentPart('last');
  Object3D? get currentSketchLine => _getCurrentPart('line');
  Object3D? get currentSketchPoint => _getCurrentPart('point');
  Object3D? get previousSketchPoint => _getCurrentPart('previousPoint');
  Object3D get currentSketch => sketches.last;

  Object3D? _getCurrentPart(String name){
    final int len = sketches.last.children.length-1;
    if(
      (sketches.last.children.last.name == 'point' && name == 'point') ||
      (sketches.last.children.last.name == 'line' && name == 'line') || 
      name == 'last'
      ){
      return sketches.last.children.last;
    }
    else if(
      (sketches.last.children[len-1].name == 'point' && name == 'point') || 
      (sketches.last.children[len-1].name == 'line' && name == 'line') 
    ){
      return sketches.last.children[len-1];
    }
    else if(name == 'line' && sketches.last.children.first.name == 'line'){
      return sketches.last.children.first;
    }
    else if(sketches.last.name == 'lines' && sketches.last.children[len-2].name == 'point' && name == 'previousPoint'){
      return sketches.last.children[len-2];
    }
    else if(sketches.last.name == 'lines' && sketches.last.children[len-3].name == 'point' && name == 'previousPoint'){
      return sketches.last.children[len-3];
    }

    return null;
  }

  Object3D getBoxLine(int lineNumber){
    final int len = sketches.last.children.length-1;
    return sketches.last.children[len-(lineNumber-1)*2];
  }
  Object3D getBoxPoint(int pointNumber){
    final int len = sketches.last.children.length-1;
    return sketches.last.children[len-(pointNumber-1)*2-1];
  }
  List<Vector3> pointPositions(){
    List<Vector3> p = [];
    for(final o in currentSketch.children){
      if(o.name == 'point'){
        p.add(o.position);
      }
    }

    return p;
  }

  List<Object3D> get allObjects => _allObjects();
  List<Object3D> get allPoints => _allPoints();
  List<Object3D> get allLines => _allLines();
  List<Object3D> get allSelectables => _allSelectables();
  List<Object3D> _allObjects(){
    List<Object3D> o = [];
    for(final g in sketches){
      o.addAll(g.children);
    }
    if(o.isNotEmpty){
      if(o.last == currentSketchPart){
        o.removeLast();
      }
      else if(o.length-2 >= 0 && o[o.length-2] == currentSketchPoint){
        o.removeAt(o.length-2);
      }
    }
    return o;
  }
  List<Object3D> _allPoints(){
    List<Object3D> o = [];
    for(final gr in sketches){
      for(final g in gr.children){
        if(g.name == 'point'){
          o.add(g);
        }
      }
    }
    if(o.isNotEmpty){
      if(o.last == currentSketchPart){
        o.removeLast();
      }
      else if(o.length-2 >= 0 && o[o.length-2] == currentSketchPoint){
        o.removeAt(o.length-2);
      }
    }
    return o;
  }
  List<Object3D> _allSelectables(){
    List<Object3D> o = [];
    for(final gr in sketches){
      for(final g in gr.children){
        if((g.name == 'line' || g.name == 'point') && !ignore.contains(g)){
          o.add(g);
        }
      }
    }
    return o;
  }
  List<Object3D> get ignore => _ignore();
  List<Object3D> _ignore(){
    final cp = sketches.last;
    if(cp.name != 'points' && cp.name != 'lines' && cp.name != 'spline' && newSketchDidStart){
      return cp.children;
    }
    else if(newSketchDidStart && cp.name == 'points'){
      return[currentSketchPoint!];
    }
    else if(newSketchDidStart && (cp.name == 'lines' || cp.name == 'spline')){
      return[currentSketchPoint!, currentSketchLine!];
    }

    return [];
  }
  List<Object3D> _allLines(){
    List<Object3D> o = [];
    for(final gr in sketches){
      for(final g in gr.children){
        if(g.name == 'line'){
          o.add(g);
        }
      }
    }
    return o;
  }
  void minorDispose(){
    for(final t in toDispose){
      t.dispose();
    }
    toDispose = [];
  }

  void remove(){

  }
  void removeLast(){
    toDispose.addAll(sketches.last.children);
    sketches.last.removeList(sketches.last.children.sublist(0));
  }
  void removeCurrent(){
    sketches.last.remove(sketches.last.children.last);
  }
}

class Draw with EventDispatcher{
  double scale = 100;
  final mat.ThemeData theme;
  final mat.BuildContext context;
  Group drawScene = Group();
  Camera camera;
  late mat.GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;
  DrawType _drawType = DrawType.none;
  Constraints constraintType = Constraints.none;
  DrawType get drawType => _drawType;

  late Object3D origin;
  List<Object3D> _hovered = [];
  final _pointer = Vector2.zero();
  final Raycaster _raycaster = Raycaster()
      ..params['Points']['threshold'] = 0.05
      ..params['Line2'] = {'threshold':0.05}
      ..params['Line']['threshold'] = 0.04;

  Sketch? sketch;
  List<Object3D> selected = [];

  late void Function() update;
  
  Draw(
    this.camera, 
    Object3D origin, 
    this.listenableKey,
    this.theme,
    this.context,
    this.update
  ){
    final color = theme.brightness == mat.Brightness.light?0x000000:0xffffff;
    this.origin = DrawType.creatPoint(Vector3(),color)..name = 'o';
    origin.visible = false;
    drawScene.add(this.origin);
    domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.addEventListener(PeripheralType.pointerHover, onPointerMove);
    hide();
  }

  void hide(){
    for(int i = 0; i < (sketch?.sketches.length ?? 0);i++){
      if(sketch?.sketches[i].name == 'dimension'){
        sketch?.sketches[i].visible = false;
      }
    }
    drawScene.visible = false;
  }
  void show(){
    drawScene.visible = true;
  }

  void dispose(){
    domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.removeEventListener(PeripheralType.pointerHover, onPointerMove);
  }

  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as mat.RenderBox;
    final size = box.size;
    _pointer.x = ((event.clientX) / size.width * 2 - 1);
    _pointer.y = (-(event.clientY) / size.height * 2 + 1);
  }

  void startSketch(DrawType drawType){
    _drawType = drawType;
    sketch?.newSketch = true;
    sketch?.newSketchDidStart = false;
  }
  void endSketch([bool cancel = false]){
    if(sketch?.newSketchDidStart == true){
      switch (_drawType) {
        case DrawType.line:
          sketch?.toDispose.add(sketch!.currentSketchPart!);
          sketch?.removeCurrent();
          sketch?.toDispose.add(sketch!.currentSketchPart!);
          sketch?.removeCurrent();
          break;
        case DrawType.point:
          sketch?.toDispose.add(sketch!.currentSketchPart!);
          sketch?.removeCurrent();
          break;
        case DrawType.spline:
          sketch?.toDispose.add(sketch!.currentSketchPart!);
          sketch?.removeCurrent();
          DrawType.updateSplineOutline(sketch!.currentSketchLine as dynamic, sketch!.pointPositions());
          break;
        default:
          if(cancel){
            sketch?.removeLast();
          }
      }
    }
    clearSelected();
    _drawType = DrawType.none;
    sketch?.newSketch = false;
    sketch?.newSketchDidStart = false;
    update();
  }

  void checkSelected(){
    for(final o in selected){
      if(o.name == 'o'){
        origin.visible = true;
      }
      if(!selected.contains(o)){
        if(o.material?.userData['isHighlighted'] == null || o.material?.userData['isHighlighted'] == false){
          changeObjectColor(o);
        }
      }
    }
  }
  void clearSelected(){
    for(final o in selected){
      o.material?.userData['isHighlighted'] = false;
      o.material?.color = o.material?.userData['origionalColor'] ?? o.material?.color;
    }
    selected.clear();
  }
  void clearSelectedHighlight(Object3D o){
    o.material?.userData['isHighlighted'] = false;
    o.material?.color = o.material?.userData['origionalColor'] ?? o.material?.color;
    selected.remove(o);
  }
  void changeObjectColor(Object3D? newObject){
    Object3D? object = newObject;
    newObject?.material?.userData['isHighlighted'] = true;
    bool isDimension = newObject?.parent?.name == 'dimension';

    if(newObject is Line && newObject.children.isNotEmpty && newObject.children[0] is Line2){
      object = newObject.children[0];
      object.material?.linewidth =  4;
    }
    else if(object is Points){
      object.material?.size =  10;
    }

    object?.material?.userData['origionalColor'] = isDimension? object.material?.color:
    object.material?.color.getHex() == 0xffffff?Color.fromHex32(theme.secondaryHeaderColor.toARGB32()):object.material?.color;
    object?.material?.color = isDimension?Color.fromHex32(theme.secondaryHeaderColor.toARGB32()):object.material!.color.lighten(0.25);// = Color.fromHex32(0xffffff);
  }
  void checkHighLight(List<Intersection> inter){
    for(final i in inter){
      if(i.object?.name == 'o'){
        origin.visible = true;
        _hovered.add(i.object!);
      }
      else{
        if(i.object?.name != 'SketchPlane'){
          if(i.object?.material?.userData['isHighlighted'] == null || i.object?.material?.userData['isHighlighted'] == false){
            changeObjectColor(i.object);
            _hovered.add(i.object!);
          }
        }
      }
    }
  }
  void clearHighlight(){
    origin.visible = false;
    for(final o in _hovered){
      if(!selected.contains(o)){
        o.material?.userData['isHighlighted'] = false;
        if(o is Line && o.children.isNotEmpty && o.children[0] is Line2){
          o.children[0].material?.color = o.children[0].material?.userData['origionalColor'] ?? o.children[0].material?.color;
          o.children[0].material?.linewidth =  2;
        }
        else{
          o.material?.color = o.material?.userData['origionalColor'] ?? o.material?.color;
          if(o is Points){
            o.material?.size =  7.5;
          }
        }
      }
    }
    _hovered = [];
  }

  List<Intersection> _getObjectIntersections(){
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObjects([origin]+sketch!.allSelectables,false);
  }
  List<Intersection> _getAllIntersections(WebPointerEvent event){
    updatePointer(event);
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObjects([sketch!.meshPlane,origin]+sketch!.allSelectables,false);
  }
  List<Intersection> _getIntersections(){
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObject(sketch!.meshPlane,false);
  }
  void onPointerMove(WebPointerEvent event) {
    if(sketch != null){
      final intersections = _getAllIntersections(event);
      clearHighlight();
      checkHighLight(intersections);
      checkSelected();
      if(intersections.isNotEmpty && sketch!.sketches.isNotEmpty){
        if(sketch?.newSketchDidStart == true){
          _updateDraw(intersections[0].point!);
        }
        else if(sketch!.sketches.isNotEmpty){
          _updateDraw(intersections[0].point!);
        }
      }
    }
  }

  Vector3 getPointInBetweenByPerc(Vector3 p1, Vector3 p2, double percentage) {
    Vector3 dir = p2.clone().sub(p1);
    final len = dir.length;
    dir = dir.normalize().scale(len*percentage);
    return p1.clone().add(dir);
  }

  void _updateConstraint(){
    if(selected.length < 2) return;

    switch (constraintType) {
      case Constraints.coincident:
        if(selected[0].name != 'point'){
          clearSelectedHighlight(selected[0]);
        }
        else if(selected[1].name != 'point'){
          clearSelectedHighlight(selected[1]);
        }
        else{
          if(selected[0].parent?.name != 'circleSpline'){
            final center = selected[0].parent!.children.last.position.clone();
          }
          else if(selected[1].parent?.name != 'circleSpline'){
            final center = selected[1].parent!.children.last.position.clone();
          }

          

          clearSelected();
        }
        break;
      case Constraints.concentric:
        if(selected[0].parent?.name != 'circleSpline'){
          clearSelectedHighlight(selected[0]);
        }
        else if(selected[1].parent?.name != 'circleSpline'){
          clearSelectedHighlight(selected[1]);
        }
        else{
          final c1 = selected[0].parent!;
          final c2 = selected[1].parent!;

          final center = c2.children.last.position.clone();

          final temp = c1.children.last.position;
          final position = c1.children[0].geometry!.attributes['position'] as Float32BufferAttribute;
          final dist = temp.distanceTo(Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble()));

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

          clearSelected();
        }
      case Constraints.midpoint:
       if(selected[0].parent?.name == 'circleSpline'){
          clearSelectedHighlight(selected[0]);
        }
        else if(selected[1].parent?.name == 'circleSpline'){
          clearSelectedHighlight(selected[1]);
        }
        else if(selected[0].name == 'line' && selected[1].name == 'line'){
          final position = selected[0].geometry!.attributes['position'] as Float32BufferAttribute;
          final p11 = Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble());
          final p12 = Vector3(position.getX(1)!.toDouble(),position.getY(1)!.toDouble(),position.getZ(1)!.toDouble());
          final midPoint = getPointInBetweenByPerc(p11, p12, 0.50);

          final position2 = selected[1].geometry!.attributes['position'] as Float32BufferAttribute;
          final p21 = Vector3(position2.getX(0)!.toDouble(),position2.getY(0)!.toDouble(),position2.getZ(0)!.toDouble());
          final p22 = Vector3(position2.getX(1)!.toDouble(),position2.getY(1)!.toDouble(),position2.getZ(1)!.toDouble());
          final midPoint2 = getPointInBetweenByPerc(p21, p22, 0.50);


        }
        else if(selected[0].name == 'line' && selected[1].name == 'point'){
          final position = selected[0].geometry!.attributes['position'] as Float32BufferAttribute;
          final p1 = Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble());
          final p2 = Vector3(position.getX(1)!.toDouble(),position.getY(1)!.toDouble(),position.getZ(1)!.toDouble());

          selected[1].position.setFrom(getPointInBetweenByPerc(p1, p2, 0.50));
          clearSelected();
        }
        else if(selected[0].name == 'point' && selected[1].name == 'line'){
          final position = selected[1].geometry!.attributes['position'] as Float32BufferAttribute;
          final p1 = Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble());
          final p2 = Vector3(position.getX(1)!.toDouble(),position.getY(1)!.toDouble(),position.getZ(1)!.toDouble());

          selected[0].position.setFrom(getPointInBetweenByPerc(p1, p2, 0.50));

          clearSelected();
        }
        else if((selected[0].name == 'line' && selected[1].name == 'origin') || (selected[0].name == 'origin' && selected[1].name == 'line')){
          final position = selected[1].geometry!.attributes['position'] as Float32BufferAttribute;
          final p1 = Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble());
          final p2 = Vector3(position.getX(1)!.toDouble(),position.getY(1)!.toDouble(),position.getZ(1)!.toDouble());

          selected[0].position.setFrom(getPointInBetweenByPerc(p1, p2, 0.50));

          clearSelected();
        }
        else{
          clearSelected();
        }
        break;
      default:
    }
  }
  void _updateDraw(Vector3 point){
    if(sketch?.newSketchDidStart == false) return;
    switch (drawType) {
      case DrawType.dimensions:
        if(selected[0].name == 'circleSpline'){
          final p1 = selected[0].children.last.position;
          final position = selected[0].children[0].geometry!.attributes['position'] as Float32BufferAttribute;
          final dist = p1.distanceTo(Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble()));

          final forwardVector = Vector3();
          final rightVector = Vector3();
          final rightVector2 = Vector3();
          camera.getWorldDirection(forwardVector);
          rightVector.cross2(camera.up, forwardVector).normalize();
          double angle = -rightVector.angleTo(point);
          
          final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);
          double angle2 = upVector.angleTo(point);

          if(angle < math.pi && angle2 < math.pi/2){
            angle = -angle;
          }

          final rotation1 = Quaternion();
          rotation1.setFromAxisAngle(forwardVector, angle);

          final rotation2 = Quaternion();
          rotation2.setFromAxisAngle(forwardVector, angle+math.pi/2);

          rightVector2.setFrom(rightVector).applyQuaternion(rotation1);
          upVector.applyQuaternion(rotation2);

          final p2 = p1.clone().add(rightVector2.clone().scale(dist));
          final p3 = p1.clone().add(upVector.clone().scale(dist));
          final p4 = point.clone();
          final p5 = point.clone().add(rightVector.clone().scale(-0.2));
          final p6 = point.clone().add(rightVector.clone().scale(-0.1));

          sketch!.sketches.last.children[0].position.setFrom(p2);
          sketch!.sketches.last.children[1].position.setFrom(p3);
          
          setLineFromPoints(sketch!.sketches.last.children[2], p1, p2);
          setLineFromPoints(sketch!.sketches.last.children[3], p2, p3);
          setLineFromPoints(sketch!.sketches.last.children[4], p2, p4);
          setLineFromPoints(sketch!.sketches.last.children[5], p4, p5);

          sketch!.sketches.last.children[6]
            ..position.setFrom(p6);
            //..lookAt(camera.position);
            //..applyQuaternion(rotation2);
        }
        break;
      case DrawType.point:
        sketch!.currentSketchPoint!.position.setFrom(point);
        break;
      case DrawType.line:
        sketch!.currentSketchPoint!.position.setFrom(point);
        final v = sketch!.previousSketchPoint!.position.clone();
        setLineFromPoints(sketch!.currentSketchLine!, v, point.clone());
        break;
      case DrawType.box2Point:
        final p1 = sketch!.sketches.last.children[0].position.clone();

        final forwardVector = Vector3();
        final rightVector = Vector3();
        camera.getWorldDirection(forwardVector);
        rightVector.cross2(camera.up, forwardVector).normalize();
        final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);

        final s1 = Plane().setFromNormalAndCoplanarPoint(upVector, p1).distanceToPoint(point);
        final s2 = Plane().setFromNormalAndCoplanarPoint(rightVector, p1).distanceToPoint(point);

        final p2 = sketch!.sketches.last.children[4].position.setFrom(p1).add(rightVector.clone().scale(s2));
        final p3 = sketch!.sketches.last.children[2].position.setFrom(point);
        final p4 = sketch!.sketches.last.children[6].position.setFrom(p1).add(upVector.clone().scale(s1));

        setLineFromPoints(sketch!.sketches.last.children[1], p1, p2);
        setLineFromPoints(sketch!.sketches.last.children[3], p2, p3);
        setLineFromPoints(sketch!.sketches.last.children[5], p3, p4);
        setLineFromPoints(sketch!.sketches.last.children[7], p4, p1);

        break;
      case DrawType.circleCenter:
        final center = sketch!.sketches.last.children[1].position.clone();

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

        DrawType.updateSplineOutline(sketch!.sketches.last.children[0] as dynamic, [p1,p2,p3,p4], true, 64);
        break;
      case DrawType.boxCenter:
        final center = sketch!.sketches.last.children[8].position.clone();

        final forwardVector = Vector3();
        final rightVector = Vector3();
        camera.getWorldDirection(forwardVector);
        rightVector.cross2(camera.up, forwardVector).normalize();
        final upVector = Vector3(0, 1, 0).applyQuaternion(camera.quaternion);

        final s1 = Plane().setFromNormalAndCoplanarPoint(upVector, center).distanceToPoint(point);
        final s2 = Plane().setFromNormalAndCoplanarPoint(rightVector, center).distanceToPoint(point);

        final p1 = sketch!.sketches.last.children[0].position.setFrom(point).add(upVector.clone().scale(-s1 * 2));
        final p2 = sketch!.sketches.last.children[2].position.setFrom(point);
        final p3 = sketch!.sketches.last.children[4].position.setFrom(point).add(rightVector.clone().scale(-s2 * 2));
        final p4 = sketch!.sketches.last.children[6].position.setFrom(sketch!.sketches.last.children[0].position).add(rightVector.clone().scale(-s2 * 2));

        setLineFromPoints(sketch!.sketches.last.children[1], p1, p2);
        setLineFromPoints(sketch!.sketches.last.children[3], p2, p3);
        setLineFromPoints(sketch!.sketches.last.children[5], p3, p4);
        setLineFromPoints(sketch!.sketches.last.children[7], p4, p1);

        setLineFromPoints(sketch!.sketches.last.children[9], p1, p3);
        setLineFromPoints(sketch!.sketches.last.children[10], p2, p4);

        (sketch!.sketches.last.children[9] as dynamic).computeLineDistances();
        (sketch!.sketches.last.children[10] as dynamic).computeLineDistances();
        break;
      case DrawType.spline:
        sketch!.currentSketchPoint!.position.setFrom(point);
        DrawType.updateSplineOutline(sketch!.currentSketchLine as dynamic, sketch!.pointPositions());
        break;
      default:
    }
  }

  void setLineFromPoints(Object3D object, Vector3 p1, Vector3 p2){
    if(object is! Line2){
      setSLineFromPoints(object.geometry!, p1, p2);
      if(object.children[0] is Line2){
        setFatLineFromPoints(object.children[0].geometry!, p1, p2);
        (object.children[0] as Line2).computeLineDistances();
      }
    }
    else{
      setFatLineFromPoints(object.geometry!, p1, p2);
      object.computeLineDistances();
    }
  }
  void setFatLineFromPoints(BufferGeometry geometry, Vector3 p1, Vector3 p2){
    geometry.attributes["instanceStart"].array[0] = p1.x;
    geometry.attributes["instanceStart"].array[1] = p1.y;
    geometry.attributes["instanceStart"].array[2] = p1.z;
    geometry.attributes["instanceStart"].array[3] = p2.x;
    geometry.attributes["instanceStart"].array[4] = p2.y;
    geometry.attributes["instanceStart"].array[5] = p2.z;

    geometry.attributes["instanceStart"].needsUpdate = true;
  }
  void setSLineFromPoints(BufferGeometry geometry, Vector3 p1, Vector3 p2){
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
  void onPointerDown(WebPointerEvent event) {
    if(sketch != null){
      if(event.button == 0){
        final intersections = _getIntersections();
        final intersectObjects = _getObjectIntersections();
        bool isLine = false;
        bool isPoint = false;
        Object3D? parent;
        Object3D? didSelect;
        Vector3? point;
        if(intersections.isNotEmpty){
          for(final i in intersectObjects){
            final o = i.object!;
            if(o.name == 'o'){
              didSelect = o.parent;
              point = origin.position;
              break;
            }
            if(o.name == 'point'){
              point = o.position;
              didSelect = o;
              parent = o.parent;
              isPoint = true;
              break;
            }
            if(o.name == 'line'){
              parent = o.parent;
              didSelect = o;
              point = i.point;
              isLine = true;
            }
          }

          point ??= intersections[0].point!;

          switch (drawType) {
            case DrawType.point:
              drawPoint(point);
              break;
            case DrawType.dimensions:
              if(isLine) drawDimension(point,parent, true);
              else if(isPoint) drawDimension(point,parent, false);
              else if(sketch?.newSketch == true && sketch?.newSketchDidStart == true) endSketch(); 
              break;
            case DrawType.line:
              drawLine(point);
              break;
            case DrawType.box2Point:
              drawBox2P(point);
              break;
            case DrawType.circleCenter:
              drawCircleCenter(point);
              break;
            case DrawType.boxCenter:
              drawBoxCenter(point);
              break;
            case DrawType.spline:
              drawSpline(point);
              break;
            default:
              if(didSelect != null && constraintType != Constraints.none){
                selected.add(didSelect);
                _updateConstraint();
              }
              else if(parent?.name == 'lines'){
                
              }
          }
        }
      }
    }
  }

  void drawBoxCenter(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.add(
        DrawType.createBoxCenter(mousePosition, theme.secondaryHeaderColor.toARGB32())
      );
      sketch?.render.add(sketch?.currentSketch);
      sketch?.newSketchDidStart = true;
    }
    else{
      _updateDraw(mousePosition);
      endSketch();
    }
  }
  void drawSpline(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.add(DrawType.createSpline(mousePosition,theme.secondaryHeaderColor.toARGB32()));
      sketch?.render.add(sketch?.currentSketch);
      sketch?.newSketchDidStart = true;
    }
    else{
      sketch!.currentSketchPoint!.position.setFrom(mousePosition);
      _updateDraw(mousePosition);
      addPoint(mousePosition);
    }
  }
  void drawCircleCenter(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.add(DrawType.createCircleSpline(mousePosition,theme.secondaryHeaderColor.toARGB32()));
      sketch?.render.add(sketch?.currentSketch);
      sketch?.newSketchDidStart = true;
    }
    else{
      _updateDraw(mousePosition);
      endSketch();
    }
  }
  // void drawCircleCenter2(Vector3 mousePosition){
  //   if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
  //     sketch?.sketches.add(DrawType.createCircle(mousePosition, sketch!.meshPlane.rotation));
  //     sketch?.render.add(sketch?.currentSketch);
  //     sketch?.newSketchDidStart = true;
  //   }
  //   else{
  //     _updateDraw(mousePosition);
  //     for(final o in sketch!.sketches.last.children){
  //       if(o.name == 'circleLines'){
  //         for(final l in o.children){
  //           l.geometry?.attributes["position"].needsUpdate = true;
  //           l.geometry?.computeBoundingSphere();
  //           l.geometry?.computeBoundingBox();
  //         }
  //       }
  //     }
  //     endSketch();
  //   }
  // }
  void drawBox2P(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.add(DrawType.createBox2Point(mousePosition, theme.secondaryHeaderColor.toARGB32()));
      sketch?.render.add(sketch?.currentSketch);
      sketch?.newSketchDidStart = true;
    }
    else{
      _updateDraw(mousePosition);
      endSketch();
    }
  }
  void drawDimension(Vector3 mousePosition, Object3D? select, bool fromLine){
    final color = theme.brightness == mat.Brightness.light?0x000000:0xffffff;
    if(fromLine && sketch?.newSketch == true && sketch?.newSketchDidStart == false && select?.name == 'circleSpline'){
      final g = Group()..name = 'dimension';
      sketch?.sketches.add(g);
      //selected.userData['constraints'] = ;
      addPoint(mousePosition,color);
      addPoint(mousePosition,color);

      addLine(mousePosition,color);
      addLine(mousePosition,color);
      addLine(mousePosition,color);
      addLine(mousePosition,color);

      final p1 = select!.children.last.position;
      final position = select.children[0].geometry!.attributes['position'] as Float32BufferAttribute;
      final dist = p1.distanceTo(Vector3(position.getX(0)!.toDouble(),position.getY(0)!.toDouble(),position.getZ(0)!.toDouble()));

      addPlane('θ ${(dist*scale).toStringAsFixed(3)}',theme.brightness == mat.Brightness.light?0x00000000:0xffffffff).then((_){
        sketch?.render.add(g);
        sketch?.newSketchDidStart = true;

        selected.add(select);
        _updateDraw(mousePosition);
      });
    }
    else if(fromLine && sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      final g = Group()..name = 'dimension';
      sketch?.sketches.add(g);
      addPoint(mousePosition,color);
      addPoint(mousePosition,color);

      addLine(mousePosition,color);
      addLine(mousePosition,color);
      addLine(mousePosition,color);

      addPlane('0.00',theme.brightness == mat.Brightness.light?0x00000000:0xffffffff).then((_){
        sketch?.render.add(g);
        sketch?.newSketchDidStart = true;

        selected.add(select!);
        _updateDraw(mousePosition);
      });
    }
  }
  void drawLine(Vector3 mousePosition){
    if(sketch?.newSketch ==true && sketch?.newSketchDidStart == false){
      sketch?.sketches.add(Group()..name = 'lines');
      addPoint(mousePosition);
      addLine(mousePosition);
      addPoint(mousePosition);
      sketch?.render.add(sketch?.currentSketch);
      sketch?.newSketchDidStart = true;
    }
    else{
      sketch!.currentSketchPoint!.position.setFrom(mousePosition);
      _updateDraw(mousePosition);
      addLine(mousePosition);
      addPoint(mousePosition);
    }
  }
  void drawPoint(Vector3 mousePosition){
    if(sketch?.newSketch == true && sketch?.newSketchDidStart == false){
      sketch?.sketches.add(Group()..name = 'points');
      sketch?.render.add(sketch?.currentSketch);
      addPoint(mousePosition);
      addPoint(mousePosition);
      sketch?.newSketchDidStart = true;
    }
    else{
      sketch!.currentSketchPoint!.position.setFrom(mousePosition);
      _updateDraw(mousePosition);
      addPoint(mousePosition);
    }
  }
  
  void addPoint(Vector3 mousePosition, [int? color]){
    sketch?.currentSketch.add(DrawType.creatPoint(mousePosition, color??theme.secondaryHeaderColor.toARGB32()));
  }
  void addLine(Vector3 mousePosition,[int? color]){
    sketch?.currentSketch.add(DrawType.createLine(mousePosition, color??theme.secondaryHeaderColor.toARGB32()));
  }
  Future<void> addPlane(String value, int color) async{
    final texture = await FlutterTexture.fromWidget(
      context,
      mat.Transform.flip(
        //flipX: !kIsWeb?true:false,
        flipY: !kIsWeb?true:false,
        child: mat.Container(
          width: 250,
          height: 100,
          color: mat.Colors.transparent,
          alignment: mat.Alignment.topCenter,
          child: mat.Text(
            value,
            style: mat.TextStyle(
              fontSize: 36,
              color: mat.Color(0xffffffff)
            ),
          ),
        ),
      )
    );
    final geometry = PlaneGeometry(0.25,0.1);
    final material = MeshBasicMaterial.fromMap( {
      'map': texture,
      'side': DoubleSide,
      'transparent': true,
    } )
    ..depthWrite = true
    ..depthTest = false;

    final mesh = Mesh(geometry,material)..lookAt(camera.up);
    sketch?.scale.add(mesh);
    sketch?.currentSketch.add(mesh);
  }

  void start(Sketch sketch){
    show();
    this.sketch = sketch;

    drawScene.add(sketch.meshPlane);
    drawScene.add(sketch.render);
  }
  void finish(){
    if(_drawType != DrawType.none){
      endSketch();
    }

    drawScene.remove(sketch!.meshPlane);
    drawScene.remove(sketch!.render);

    hide();
    sketch = null;
  }
  void updateScale(){
    final scale = 1.5;
    for(int i = 0; i < (sketch?.scale.length ?? 0); i++){
      sketch?.scale[i].scale.setValues(scale/camera.zoom, scale/camera.zoom, scale/camera.zoom);
    }
  }
  void cancel(){
    finish();
  }
}