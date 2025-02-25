import 'package:flutter/material.dart' hide Material;
import 'package:three_cad/src/cad/draw_types.dart';
import 'package:three_js/three_js.dart';

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
  List<Object3D> toDispose = [];

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
    else if(sketches.last.children[len-2].name == 'point' && name == 'previousPoint'){
      return sketches.last.children[len-2];
    }
    else if(sketches.last.children[len-3].name == 'point' && name == 'previousPoint'){
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
  void minorDispose(){
    for(final t in toDispose){
      t.dispose();
    }
    toDispose = [];
  }

  void remove(){

  }
  void removeCurrent(){
    sketches.last.remove(sketches.last.children.last);
  }
}

class Draw with EventDispatcher{
  Group drawScene = Group();
  Camera camera;
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;
  DrawType _drawType = DrawType.none;
  DrawType get drawType => _drawType;

  late Object3D origin;
  List<Object3D> _hovered = [];
  final _pointer = Vector2.zero();
  final Raycaster _raycaster = Raycaster()
      ..params['Points']['threshold'] = 0.05
      ..params['Line']['threshold'] = 1.0;

  bool _newSketch = false;
  bool _newSketchDidStart = false;

  Sketch? sketch;

  void Function() update;
  
  Draw(
    this.camera, 
    Object3D origin, 
    this.listenableKey,
    this.update
  ){
    this.origin = DrawType.creatPoint(Vector3(),0xffffff)..name = 'o';
    origin.visible = false;
    drawScene.add(this.origin);
    domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.addEventListener(PeripheralType.pointerHover, onPointerMove);
    hide();
  }

  void hide(){
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
    final box = listenableKey.currentContext?.findRenderObject() as RenderBox;
    final size = box.size;
    _pointer.x = ((event.clientX) / size.width * 2 - 1);
    _pointer.y = (-(event.clientY) / size.height * 2 + 1);
  }

  void startSketch(DrawType drawType){
    _drawType = drawType;
    _newSketch = true;
    _newSketchDidStart = false;
  }
  void endSketch(){
    if(_newSketchDidStart){
      switch (_drawType) {
        case DrawType.line:
          sketch?.toDispose.add(sketch!.currentSketchPart!);
          sketch?.removeCurrent();
          sketch?.toDispose.add(sketch!.currentSketchPart!);
          sketch?.removeCurrent();
          break;
        case DrawType.spline:
          sketch?.toDispose.add(sketch!.currentSketchPart!);
          sketch?.removeCurrent();
          DrawType.updateSplineOutline(sketch!.currentSketchLine as Line, sketch!.pointPositions());
        break;
        default:
      }
    }
    _drawType = DrawType.none;
    _newSketch = false;
    _newSketchDidStart = false;
    update();
  }

  void checkHighLight(List<Intersection> inter){
    for(final i in inter){
      if(i.object?.name == 'o'){
        origin.visible = true;
        _hovered.add(i.object!);
      }
      else{
        if(i.object?.name != 'SketchPlane'){
          i.object!.material?.opacity = 1.0;
          _hovered.add(i.object!);
        }
      }
    }
  }
  void setHighlight(Object3D? object){
    if(object?.name == 'o'){
      origin.visible = true;
    }

    if(object != null){
      object.material?.opacity = 1.0;
      _hovered.add(object);
    }
    
  }
  void clearHighlight(){
    origin.visible = false;
    for(final o in _hovered){
      o.material?.opacity = 0.5;
    }
    _hovered = [];
  }

  List<Intersection> _getAllIntersections(WebPointerEvent event){
    updatePointer(event);
    _raycaster.setFromCamera(_pointer, camera);
    return _raycaster.intersectObjects([sketch!.meshPlane,origin]+sketch!.allPoints,false);
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
      // if(intersections.length > 1 && 
      //   intersections[1].object?.name != 'SketchPlane' && 
      //   _newSketch
      // ){
      //   setHighlight(intersections[1].object);
      // }
      // else if(intersections.isNotEmpty && 
      //   intersections[0].object?.name == 'o'
      // ){
      //   setHighlight(intersections[0].object);
      // }
      // else{
      //   clearHighlight();
      // }

      if(_newSketchDidStart && sketch!.sketches.isNotEmpty ){
        if(intersections.isNotEmpty){
          _update(intersections[0].point!);
        }
      }
      else if(sketch!.sketches.isNotEmpty){
        if(intersections.isNotEmpty){
          _update(intersections[0].point!);
        }
      }
    }
  }

  void _update(Vector3 point){
    switch (drawType) {
      case DrawType.line:
        sketch!.currentSketchPoint!.position.setFrom(point);
        final v = sketch!.previousSketchPoint!.position.clone();
        sketch!.currentSketchLine!.geometry?.setFromPoints([v, point.clone()]);
        break;
      case DrawType.box2Point:
        final v1 = sketch!.sketches.last.position;
        Vector3 scale = point.clone().sub(v1);
        sketch!.sketches.last.scale = scale;
        break;
      case DrawType.circle:
        final v1 = sketch!.currentSketchPoint!.position;
        final dist = point.distanceTo(v1);
        sketch!.sketches.last.children.last.scale = Vector3(dist,dist,dist);
        break;
      case DrawType.boxCenter:
        final v1 = sketch!.sketches.last.position;
        Vector3 scale = point.clone().sub(v1);
        sketch!.sketches.last.scale = scale;
        break;
      case DrawType.spline:
        sketch!.currentSketchPoint!.position.setFrom(point);
        DrawType.updateSplineOutline(sketch!.currentSketchLine as Line, sketch!.pointPositions());
        break;
      default:
    }
  }
  void onPointerDown(WebPointerEvent event) {
    if(sketch != null){
      if(event.button == 0){
        final intersections = _getIntersections();
        Vector3? point;
        if(intersections.isNotEmpty){
          for(final i in _hovered){
            if(i.name == 'o'){
              point = origin.position;
              break;
            }
            if(i.name == 'point'){
              point = i.position;
              break;
            }
          }

          point ??= intersections[0].point!;

          switch (drawType) {
            case DrawType.line:
              drawLine(point);
              break;
            case DrawType.box2Point:
              drawBox2P(point);
              break;
            case DrawType.circle:
              drawCircle(point);
              break;
            case DrawType.boxCenter:
              drawBoxCenter(point);
              break;
            case DrawType.spline:
              drawSpline(point);
              break;
            default:
          }
        }
      }
    }
  }
  void drawBoxCenter(Vector3 mousePosition){
    if(_newSketch && !_newSketchDidStart){
      sketch?.sketches.add(
        DrawType.createBoxCenter(mousePosition)
        ..rotation = sketch!.meshPlane.rotation
      );
      sketch?.render.add(sketch?.currentSketch);
      _newSketchDidStart = true;
    }
    else{
      _update(mousePosition);
      endSketch();
    }
  }
  void drawSpline(Vector3 mousePosition){
    if(_newSketch && !_newSketchDidStart){
      sketch?.sketches.add(DrawType.createSpline(mousePosition));
      sketch?.render.add(sketch?.currentSketch);
      _newSketchDidStart = true;
    }
    else{
      sketch!.currentSketchPoint!.position.setFrom(mousePosition);
      _update(mousePosition);
      addPoint(mousePosition);
    }
  }
  void drawCircle(Vector3 mousePosition){
    if(_newSketch && !_newSketchDidStart){
      sketch?.sketches.add(DrawType.createCircle(mousePosition));
      sketch?.render.add(sketch?.currentSketch);
      _newSketchDidStart = true;
    }
    else{
      _update(mousePosition);
      endSketch();
    }
  }
  void drawBox2P(Vector3 mousePosition){
    if(_newSketch && !_newSketchDidStart){
      sketch?.sketches.add(DrawType.createBox2Point(mousePosition));
      sketch?.render.add(sketch?.currentSketch);
      _newSketchDidStart = true;
    }
    else{
      _update(mousePosition);
      endSketch();
    }
  }
  void drawLine(Vector3 mousePosition){
    if(_newSketch && !_newSketchDidStart){
      sketch?.sketches.add(Group());
      addPoint(mousePosition);
      addLine(mousePosition);
      addPoint(mousePosition);
      sketch?.render.add(sketch?.currentSketch);
      _newSketchDidStart = true;
    }
    else{
      sketch!.currentSketchPoint!.position.setFrom(mousePosition);
      _update(mousePosition);
      addLine(mousePosition);
      addPoint(mousePosition);
    }
  }
  void addPoint(Vector3 mousePosition){
    sketch?.currentSketch.add(DrawType.creatPoint(mousePosition));
  }
  void addLine(Vector3 mousePosition,[bool construction = false]){
    sketch?.currentSketch.add(DrawType.createLine(mousePosition,construction));
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

    sketch = null;
    hide();
  }
  void cancel(){
    finish();
  }
}