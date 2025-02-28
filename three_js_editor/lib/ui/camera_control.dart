import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:flutter/material.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

enum OffsetType {
  topLeft,
  bottomLeft,
  bottomRight,
  topRight,
  center
}

class CameraControl with EventDispatcher{
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

  late Scene scene;
  late Camera camera;

  final double size;
  late final Vector2 offset;
  late Size screenSize;

  Camera rotationCamera;
  ThreeJS threeJs;

  final Vector2 _scissorPos = Vector2();
  Vector2? _pointerPos;
  OffsetType offsetType;
  final Raycaster _raycaster = Raycaster();
  late Mesh _controls;

  CameraControl({
    Vector2? offset,
    this.offsetType = OffsetType.bottomLeft,
    this.size = 1,
    required this.screenSize,
    required this.listenableKey,
    required this.rotationCamera,
    required this.threeJs,
  }) {
    this.offset = offset ?? Vector2();
    _calculatePosition();
    scene = Scene();
    camera = OrthographicCamera( - 1,1,1,-1, 0.1, 2000 );
    camera.position.z = 10;

    _controls = TransformControlsGizmo.setupGizmo(TransformControlsGizmo.gizmoInfo(GizmoType.view,ContorlsMode.gizmo));
    _controls.quaternion = rotationCamera.quaternion;
    _controls.position.setValues( 0.0, 0.0, 0.0 );
    _controls.scale.setValues( size, size, size );
    scene.add(_controls);
    activate();
  }

  void _calculatePosition(){
    if(offsetType == OffsetType.bottomLeft){
      _scissorPos.x = offset.x;
      _scissorPos.y = offset.y;
    }
    else if(offsetType == OffsetType.bottomRight){
      _scissorPos.x = threeJs.width-(offset.x+screenSize.width*1.3);
      _scissorPos.y = offset.y;
    }
    else if(offsetType == OffsetType.topLeft){
      _scissorPos.x = offset.x;
      _scissorPos.y = threeJs.height-(offset.y+screenSize.height*1.1);
    }
    else if(offsetType == OffsetType.topRight){
      _scissorPos.x = threeJs.width-(offset.x+screenSize.width*1.3);
      _scissorPos.y = threeJs.height-(offset.y+screenSize.height*1.1);
    }
    else if(offsetType == OffsetType.center){
      _scissorPos.x = (threeJs.width/2-(screenSize.width*1.3)/2);//offset.x+
      _scissorPos.y = (threeJs.height/2-(screenSize.height*1.1)/2);//offset.y+
    }
  }
  void _calculatePointerPosition(Size size){
    _pointerPos = Vector2();
    if(offsetType == OffsetType.bottomLeft){
      _pointerPos!.x = offset.x;
      _pointerPos!.y = size.height-(offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.bottomRight){
      _pointerPos!.x = size.width-(offset.x+screenSize.width);
      _pointerPos!.y = size.height-(offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.topLeft){
      _pointerPos!.x = offset.x;
      _pointerPos!.y = offset.y;//size.height-(offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.topRight){
      _pointerPos!.x = size.width-(offset.x+screenSize.width);
      _pointerPos!.y = offset.y;//size.height-(offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.center){
      _pointerPos!.x = (size.width/2-(screenSize.width)/2);//offset.x+
      _pointerPos!.y = (size.height/2-(screenSize.height)/2);//offset.y+
    }
  }
  void postProcessor(){
    threeJs.renderer?.setScissorTest( true );
    threeJs.renderer?.setScissor( _scissorPos.x, _scissorPos.y, screenSize.width*1.3, screenSize.height*1.1 );
    threeJs.renderer?.setViewport( _scissorPos.x, _scissorPos.y, screenSize.width*1.3, screenSize.height*1.1 );
    threeJs.renderer!.render(scene, camera);
    threeJs.renderer?.setScissorTest( false );
  }

  void updatePointer(event) {

  }
  void update(){
    
  }
  void onPointerDown(event) {
    final i = intersectObjectWithRay(event);
    if(i?.object?.name != null){
      if(i?.object?.name == 'X'){
        threeJs.camera.position.setValues(5,0,0);
        threeJs.camera.lookAt(Vector3(math.pi, 0, 0));
        threeJs.camera.updateMatrix();
      }
      else if(i?.object?.name == 'Y'){
        threeJs.camera.position.setValues(0,5,0);
        threeJs.camera.lookAt(Vector3(0, 0, 0));
        threeJs.camera.updateMatrix();
      }
      else if(i?.object?.name == 'Z'){
        threeJs.camera.position.setValues(0,0,5);
        threeJs.camera.lookAt(Vector3(0, 0, math.pi));
        threeJs.camera.updateMatrix();
      }
    }
  }
  void onPointerCancel(event) {

  }
  void onPointerMove(event) {

  }
  void pointerHover(Pointer pointer) {

  }
  Pointer? getPointer(WebPointerEvent event) {
    if(event.button == 0){
      final RenderBox renderBox = listenableKey.currentContext!.findRenderObject() as RenderBox;
      final size = renderBox.size;

      if(_pointerPos == null){
        _calculatePointerPosition(size);
      }

      final x_ = (event.clientX - _pointerPos!.x) / screenSize.width * 2 - 1;
      final y_ = -(event.clientY - _pointerPos!.y) / screenSize.height* 2 + 1.06;
      final button = event.button;
      return Pointer(x_, y_, button);
    }
    return null;
  }
  Intersection? intersectObjectWithRay(WebPointerEvent event) {
    final pointer = getPointer(event);
    if(pointer != null){
      _raycaster.setFromCamera(Vector2(pointer.x, pointer.y), camera);
      final all = _raycaster.intersectObject(_controls, true);
      if(all.isNotEmpty){
        return all[0];
      }
    }
    
    return null;
  }

  /// Adds the event listeners of the controls.
  void activate() {
    _domElement.addEventListener(PeripheralType.pointermove, onPointerMove);
    _domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    _domElement.addEventListener(PeripheralType.pointerup, onPointerCancel);
    //_domElement.addEventListener(PeripheralType.pointerleave, onPointerCancel);
    threeJs.addAnimationEvent((dt){
      update();
    });
  }

  /// Removes the event listeners of the controls.
  void deactivate() {
    _domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
    _domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    _domElement.removeEventListener(PeripheralType.pointerup, onPointerCancel);
    //_domElement.removeEventListener(PeripheralType.pointerleave, onPointerCancel);
  }

  void dispose(){
    clearListeners();
  } 
}