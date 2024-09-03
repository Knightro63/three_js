import 'package:flutter/material.dart' hide Material;
import 'package:three_js/three_js.dart';

enum DrawType{none,line,arc,circle,boxCenter,boxCorner}

class Draw with EventDispatcher{
  Group drawScene = Group();
  Camera camera;
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;
  DrawType _drawType = DrawType.none;
  DrawType get drawType => _drawType;
  Object3D plane;
  late Object3D origin;
  List<Object3D> _hovered = [];
  final _pointer = Vector2.zero();
  final Raycaster _raycaster = Raycaster();
  List<Intersection> _intersections = [];

  bool _clicking = false;
  bool _newLine = false;
  bool _newLineDidStart = false;
  
  Draw(this.camera, this.plane, Object3D origin, this.listenableKey){
    this.origin = origin.clone();
    drawScene.add(plane);
    drawScene.add(this.origin);
    _setupOrigin();

    domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.addEventListener(PeripheralType.pointerHover, onPointerMove);
  }

  void _setupOrigin(){
    origin.visible = false;
    origin.scale.scale(0.25);
    origin.material?.emissive = Color.fromHex32(0xffffff);
    origin.material?.opacity = 1.0;
  }

  void dispose(){
    if(_drawType != DrawType.none){
      endSketch();
    }

    drawScene.children.first.dispose();
    drawScene.children.removeAt(0);
    drawScene.children.first.dispose();
    drawScene.children.removeAt(1);
    domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.removeEventListener(PeripheralType.pointerHover, onPointerMove);

    drawScene.onAfterRender = ({Camera? camera, BufferGeometry? geometry, Map<String, dynamic>? group, Material? material, WebGLRenderer? renderer, Object3D? scene}){
      drawScene.scale.setValues(2/camera!.zoom, 2/camera.zoom, 2/camera.zoom);
    };
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

    drawScene.children.last.dispose();
    drawScene.children.removeLast();
  }

  void setHighlight(Object3D? object){
    if(object?.name == 'o'){
      drawScene.children[1].visible = true;
    }
    else if(object != null){
      //object?.material?.emissive = Color.fromHex32(0xffffff);
      object.material?.opacity = 1.0;
      _hovered.add(object);
    }
  }
  void clearHighlight(){
    drawScene.children[1].visible = false;
    for(final o in _hovered){
      o.material?.opacity = 0.5;
    }
    _hovered = [];
  }

  void onPointerMove(event) {
    updatePointer(event);
    _raycaster.setFromCamera(_pointer, camera);
    _intersections = _raycaster.intersectObjects(drawScene.children,false);
    if(_intersections.length > 1 && 
      _intersections[1].object?.name != 'SketchPlane' && 
      _newLine
    ){
      setHighlight(_intersections[1].object);
    }
    else if(_intersections.isNotEmpty && _intersections[0].object?.name == 'o'){
      drawScene.children[1].visible = true;
    }
    else{
      clearHighlight();
    }

    if(_clicking && _newLine){
      if(_intersections.isNotEmpty && drawScene.children.last.name != 'SketchPlane' && drawScene.children.last.name != 'o'){
        final intersect = _intersections[ 0 ];
        drawScene.children.last.position
        .setFrom(intersect.point!);
      }
    }
  }
  void onPointerDown(event) {
    if(event.button == 0){
      _clicking = true;
      updatePointer(event);
      _raycaster.setFromCamera(_pointer, camera);
      _intersections = _raycaster.intersectObject(drawScene.children[0],false);

      Vector3? point;
      if(_intersections.isNotEmpty){
        // for(final i in _intersections){
        //   if(i.object?.name == 'o'){
        //     point = (origin.position);
        //   }
        //   else if(i.object?.name != 'SketchPlane'){
        //     point = (i.object!.position);
        //   }
        // }

        point ??= (_intersections[0].point!);

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
  void drawLine(Vector3 mousePosition){
    if(_newLine && !_newLineDidStart){
      addPoint(mousePosition);
      addPoint(mousePosition);
      _newLineDidStart = true;
    }
    else{
      addPoint(mousePosition);
    }
  }
  void addPoint(Vector3 mousePosition){
    drawScene.add(Mesh(
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
  void finish(){
    _clicking = false;
    drawScene.clear();
  }
  void cancel(){
    _clicking = false;
    for(final object in drawScene.children){
      object.dispose();
    }
    drawScene.clear();
  }
}