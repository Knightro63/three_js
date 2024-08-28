import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart';

enum DrawType{none,line,arc,circle,boxCenter,boxCorner}

class Draw with EventDispatcher{
  List<Object3D> drawScene = [];
  Camera camera;
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;
  DrawType drawType = DrawType.none;
  Mesh plane;
  final _pointer = Vector2.zero();
  Raycaster _raycaster = Raycaster();
  final List<Intersection> _intersections = [];

  bool _clicking = false;
  
  Draw(this.camera,this.plane, this.listenableKey){
    domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.addEventListener(PeripheralType.pointerHover, onPointerMove);
  }

  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as RenderBox;
    final size = box.size;
    //final local = box.globalToLocal(const Offset(0, 0));
    _pointer.x = ((event.clientX) / size.width * 2 - 1).x;
    _pointer.y = (-(event.clientY) / size.height * 2 + 1).y;
  }
  void onPointerMove(event) {
    if(_clicking){
      updatePointer(event);
      _raycaster.setFromCamera(_pointer, camera);
      _raycaster.intersectObject(plane,false,_intersections);

      if(_intersections.isNotEmpty){
        drawScene.last.position.setFrom(_intersections[0].point!);
      }
    }
  }
  void onPointerDown(event) {
    if(event.button == 0){
      _clicking = true;
      updatePointer(event);

      _raycaster.setFromCamera(_pointer, camera);
      _raycaster.intersectObject(plane,false,_intersections);

      if(_intersections.isNotEmpty){
        switch (drawType) {
          case DrawType.line:
            drawLine(_intersections[0].point!);
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
    
  }
  void addPoint(Vector3 mousePosition){
    drawScene.add(Points(
      BufferGeometry().setAttributeFromString(
        'position',
        Float32BufferAttribute.fromList(mousePosition.toList(), 3)
      ),
      PointsMaterial.fromMap({
        'color': 0xffffff,
        'size': 4,
        'depthTest': false
      })
    ));
  }
  void finish(){
    _clicking = false;
    drawScene.clear();
  }
  void cancel(){
    _clicking = false;
    for(final object in drawScene){
      object.dispose();
    }
    drawScene.clear();
  }
}