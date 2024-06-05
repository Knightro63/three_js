import 'dart:math';
import 'package:three_js_core/three_js_core.dart';
import 'package:flutter/material.dart';
import 'package:three_js_core_loaders/loaders/texture_loader.dart';
import 'package:three_js_math/three_js_math.dart';

class Joystick with EventDispatcher{
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

  late Scene scene;
  late OrthographicCamera camera;

  final Raycaster _raycaster = Raycaster();
  final List<Intersection> _intersections = [];
  final _pointer = Vector2.zero();

  final double size;
  final bool isFixed;
  final EdgeInsets margin;
  final int color;

  late final Sprite? _backgroundSprite;
  late final Sprite? _knobSprite;

  Vector2 dragPosition = Vector2.zero();
  Vector3 origin = Vector3.zero();
  late Size screenSize;

  double intensity = 0;
  double degrees = 0;

  Joystick({
    this.isFixed = true,
    this.margin = const EdgeInsets.only(left: 10, bottom: 10),
    this.size = 80,
    required this.screenSize,
    required this.listenableKey,
    this.color = 0xFF607D8B,
  }) {
    scene = Scene();

    camera = OrthographicCamera( - screenSize.width / 2, screenSize.width / 2, screenSize.height / 2, - screenSize.height / 2, 1, 10 );
    camera.position.z = 10;

    final loader = TextureLoader();
    loader.fromAsset('assets/joystick_background.png',package: 'three_js_controls').then((value){
      final material = SpriteMaterial.fromMap({'map': value});
      _backgroundSprite = Sprite( material );
      _backgroundSprite!.center.setValues( 0.0, 0.0 );
      _backgroundSprite.scale.setValues( size, size, 1 );
      scene.add(_backgroundSprite);
    });

    loader.fromAsset('assets/joystick_knob.png',package: 'three_js_controls').then((value){
      final material = SpriteMaterial.fromMap({'map': value});
      _knobSprite = Sprite( material );
      _knobSprite!.center.setValues( 0.0, 0.0 );
      _knobSprite.scale.setValues( size/1.5, size/1.5, 1 );
      scene.add(_knobSprite);
    });

    activate();
  }

  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as RenderBox;
    final size = box.size;
    final local = box.globalToLocal(const Offset(0, 0));

    _pointer.x = (event.clientX - local.dx) / size.width * 2 - 1;
    _pointer.y = -(event.clientY - local.dy) / size.height * 2 + 1;

    final temp = sqrt(
      pow((_knobSprite!.position.x+event.movementX)-origin.x/2-12,2)
      +pow((_knobSprite.position.y-event.movementY)-origin.y/2-12,2)
    );

    if(temp > 38){
      dragPosition.x = 0;
      dragPosition.y = 0;
      intensity = 1;
    }
    else{
      dragPosition.x = event.movementX;
      dragPosition.y = -event.movementY;
      intensity = temp/38;
    }
  }

  void temp(){
    if (intensity == 0) {

      return;
    }

    if (degrees > -22.5 && degrees <= 22.5) {

    }

    if (degrees > 22.5 && degrees <= 67.5) {

    }

    if (degrees > 67.5 && degrees <= 112.5) {

    }

    if (degrees > 112.5 && degrees <= 157.5) {

    }

    if ((degrees > 157.5 && degrees <= 180) || (degrees >= -180 && degrees <= -157.5)) {

    }

    if (degrees > -157.5 && degrees <= -112.5) {

    }

    if (degrees > -112.5 && degrees <= -67.5) {

    }

    if (degrees > -67.5 && degrees <= -22.5) {

    }
  }

  void update(){
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
    if(_intersections.isNotEmpty) {
      print('end');
      dispatchEvent(Event(type: 'dragend', object: _knobSprite));
      _intersections.length = 0;
    }
  }

  void onPointerMove(event) {
    if (_intersections.isNotEmpty) {
      updatePointer(event);
      print('move');
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
    
  }
  
}