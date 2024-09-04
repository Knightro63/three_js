import 'package:flutter/material.dart' hide Material;
import 'package:three_js/three_js.dart';

enum DrawType{none,line,arc,circle,boxCenter,boxCorner}

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
  Group points = Group();
  List<Object3D> toDispose = [];

  void dispose(){
    meshPlane.dispose();
    points.dispose();
    minorDispose();
  }

  void minorDispose(){
    for(final t in toDispose){
      t.dispose();
    }
    toDispose = [];
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
  final Raycaster _raycaster = Raycaster();
  List<Intersection> _intersections = [];

  bool _clicking = false;
  bool _newLine = false;
  bool _newLineDidStart = false;

  Sketch? sketch;
  
  Draw(
    this.camera, 
    this.origin, 
    this.listenableKey
  ){
    drawScene.add(origin);
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

  void _setupOrigin(){
    origin.visible = false;
    origin.scale.scale(0.25);
    origin.material?.emissive = Color.fromHex32(0xffffff);
    origin.material?.opacity = 1.0;
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
    _newLine = true;
    _newLineDidStart = false;
  }
  void endSketch(){
    _drawType = DrawType.none;
    _newLine = false;
    _newLineDidStart = false;
    sketch?.toDispose.add(sketch!.points.children.last);
    sketch!.points.remove(sketch!.points.children.last);
  }

  void setHighlight(Object3D? object){
    if(object?.name == 'o'){
      origin.visible = true;
    }
    else if(object != null){
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

  void onPointerMove(event) {
    if(sketch != null){
      updatePointer(event);
      _raycaster.setFromCamera(_pointer, camera);
      _intersections = _raycaster.intersectObjects([sketch!.meshPlane,origin]+sketch!.points.children,false);
      
      if(_intersections.length > 1 && 
        _intersections[1].object?.name != 'SketchPlane' && 
        _newLine
      ){
        setHighlight(_intersections[1].object);
      }
      else if(_intersections.isNotEmpty && _intersections[0].object?.name == 'o'){
        origin.visible = true;
      }
      else{
        clearHighlight();
      }

      if(_clicking && _newLine && sketch!.points.children.isNotEmpty){
        if(_intersections.isNotEmpty){
          final intersect = _intersections[ 0 ];
          sketch!.points.children.last.position.setFrom(intersect.point!);
        }
      }
    }
  }
  void onPointerDown(event) {
    if(sketch != null){
      if(event.button == 0){
        _clicking = true;
        updatePointer(event);
        _raycaster.setFromCamera(_pointer, camera);
        _intersections = _raycaster.intersectObjects([sketch!.meshPlane,origin]+sketch!.points.children,false);

        Vector3? point;
        if(_intersections.isNotEmpty){
          for(final i in _intersections){
            if(i.object?.name == 'o'){
              point = (origin.position);
              break;
            }
            else if(i.object?.name != 'SketchPlane'){
              point = (i.object!.position);
            }
          }
          
          point ??= _intersections[0].point!;

          switch (drawType) {
            case DrawType.line:
              drawLine(point);
              break;
            default:
          }
        }
      }
      else{
        _clicking = false;
      }
    }
  }
  void drawLine(Vector3 mousePosition){
    if(_newLine && !_newLineDidStart){
      addPoint(mousePosition);
      addPoint(mousePosition);
      _newLineDidStart = true;
    }
    else{
      sketch!.points.children.last.position.setFrom(mousePosition);
      addPoint(mousePosition);
    }
  }
  void addPoint(Vector3 mousePosition){
    sketch?.points.add(
      Mesh(
        SphereGeometry(0.01,4,4),
        MeshBasicMaterial.fromMap({
          'color': 0xffff00,
          'transparent': true,
          'opacity': 0.5
        })
      )
      ..position.x = mousePosition.x
      ..position.y = mousePosition.y
      ..position.z = mousePosition.z
    );
  }

  void start(Sketch sketch){
    show();
    _setupOrigin();
    this.sketch = sketch;

    drawScene.add(sketch.meshPlane);
    drawScene.add(sketch.points);
  }
  void finish(){
    _clicking = false;
    if(_drawType != DrawType.none){
      endSketch();
    }
    
    origin.material?.emissive = Color.fromHex32(0x000000);
    origin.material?.opacity = 0.5;
    origin.scale.scale(4);
    origin.visible = true;

    drawScene.remove(sketch!.meshPlane);
    drawScene.remove(sketch!.points);

    sketch = null;
    hide();
  }
  void cancel(){
    finish();
  }
}