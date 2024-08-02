import 'dart:math';
import 'package:three_js_core/three_js_core.dart';
import 'package:flutter/material.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

enum JoystickMoveDirectional {
  moveUp,
  moveUpLeft,
  moveUpRight,
  moveRight,
  moveDown,
  moveDownRight,
  moveDownLeft,
  moveLeft,
  idle
}

class CameraControl with EventDispatcher{
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

  late Scene scene;
  late OrthographicCamera camera;

  final Raycaster _raycaster = Raycaster();
  final List<Intersection> _intersections = [];
  final _pointer = Vector2.zero();

  final double size;
  final EdgeInsets margin;
  final int color;

  late final Sprite? _backgroundSprite;
  late final Sprite? _knobSprite;

  Vector2 dragPosition = Vector2.zero();
  Vector3 origin = Vector3.zero();
  late Size screenSize;

  double get angle => _angle;
  double get radians => _angle*pi/180; 
  double get intensity => _intensity; 

  bool get isMoving => _intensity != 0;

  double _intensity = 0;
  double _angle = 0;

  Camera rotationCamera;

  JoystickMoveDirectional direction = JoystickMoveDirectional.idle;

  CameraControl({
    this.margin = const EdgeInsets.only(left: 10, bottom: 10),
    this.size = 80,
    required this.screenSize,
    required this.listenableKey,
    required this.rotationCamera,
    this.color = 0xFF607D8B,
  }) {
    scene = Scene();

    camera = OrthographicCamera( - screenSize.width / 2, screenSize.width / 2, screenSize.height / 2, - screenSize.height / 2, 0.1, 1000 );
    camera.position.z = 10;

    final control = TransformControlsGizmo.setupGizmo(TransformControlsGizmo.gizmoInfo(GizmoType.view,ContorlsMode.gizmo));
    control.quaternion = rotationCamera.quaternion;
    control.position.setValues( 0.0, 0.0, 0.0 );
    control.scale.setValues( size, size, 1 );
    scene.add(control);
    activate();
  }

  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as RenderBox;
    final size = box.size;
    final local = box.globalToLocal(const Offset(0, 0));

    _pointer.x = (event.clientX - local.dx) / size.width * 2 - 1;
    _pointer.y = -(event.clientY - local.dy) / size.height * 2 + 1;

    final tempKnot = Vector3(_knobSprite!.position.x+event.movementX-12,_knobSprite.position.y-event.movementY-12,1);
    final tempOrigin = Vector3(origin.x/2,origin.y/2,1);
    final len = tempKnot.distanceTo(tempOrigin);

    final deltaX = (_knobSprite.position.x+event.movementX-12) - (origin.x/2);
    final deltaY = (_knobSprite.position.y-event.movementY-1) - (origin.y/2);
    _angle = 180-(atan2(deltaY, deltaX)*180)/pi;

    if(len > (this.size/2)){
      dragPosition.x = 0;
      dragPosition.y = 0;
      _intensity = 1.0;
    }
    else{
      dragPosition.x = event.movementX;
      dragPosition.y = -event.movementY;
      _intensity = len/(this.size/2);
    }
  }
  void _updateDirection(){
    if (intensity == 0) {
      direction = JoystickMoveDirectional.idle;
      return;
    }
    if (_angle > -22.5 && _angle <= 22.5) {
      direction = JoystickMoveDirectional.moveLeft;
    }
    if (_angle > 22.5 && _angle <= 67.5) {
      direction = JoystickMoveDirectional.moveUpLeft;
    }
    if (_angle > 67.5 && _angle <= 112.5) {
      direction = JoystickMoveDirectional.moveUp;
    }
    if (_angle > 112.5 && _angle <= 157.5) {
      direction = JoystickMoveDirectional.moveUpRight;
    }
    if ((_angle > 157.5 && _angle <= 180) || (_angle >= -180 && _angle <= -157.5)) {
      direction = JoystickMoveDirectional.moveRight;
    }
    if (_angle > -157.5 && _angle <= -112.5) {
      direction = JoystickMoveDirectional.moveDownRight;
    }
    if (_angle > -112.5 && _angle <= -67.5) {
      direction = JoystickMoveDirectional.moveDown;
    }
    if (_angle > -67.5 && _angle <= -22.5) {
      direction = JoystickMoveDirectional.moveDownLeft;
    }
  }
  void update(){
    _updateDirection();
    final width = screenSize.width / 2;
    final height = screenSize.height / 2;
    _backgroundSprite?.position.setValues(-width+margin.left, -height+margin.bottom, 1 ); // bottom right
    if(_intersections.isEmpty){
      _knobSprite?.position.setValues( -width+margin.left+(size/1.5-size/2), -height+margin.bottom+(size/1.5-size/2), 1 ); // bottom right
      origin.setValues( -screenSize.width+margin.left+(size/1.5-size/2), -screenSize.height+margin.bottom+(size/1.5-size/2), 1 );
    }
  }
  void onPointerDown(event) {
    updatePointer(event);
    _intersections.length = 0;
    _raycaster.setFromCamera(_pointer, camera);
    _raycaster.intersectObject(_knobSprite!, true, _intersections);

    if (_intersections.isNotEmpty) {
      _knobSprite.position.add(dragPosition);
      dispatchEvent(Event(type: 'dragstart', object: _knobSprite));
    }
  }
  void onPointerCancel(event) {
    _intensity = 0;
    if(_intersections.isNotEmpty) {
      dispatchEvent(Event(type: 'dragend', object: _knobSprite));
      _intersections.length = 0;
    }
  }

  void onPointerMove(event) {
    if (_intersections.isNotEmpty) {
      updatePointer(event);
      _knobSprite!.position.add(dragPosition);
      dispatchEvent(Event(type: 'drag', object: _knobSprite));
    }
  }
  /// Adds the event listeners of the controls.
  void activate() {
    _domElement.addEventListener(PeripheralType.pointermove, onPointerMove);
    _domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    _domElement.addEventListener(PeripheralType.pointerup, onPointerCancel);
    //_domElement.addEventListener(PeripheralType.pointerleave, onPointerCancel);
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