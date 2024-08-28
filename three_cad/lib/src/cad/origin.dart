import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:flutter/material.dart' hide Color;
import 'package:three_js_line/three_js_line.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

enum PlaneType{none,xy,xz,yz}

class Origin with EventDispatcher{
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

  final Raycaster _raycaster = Raycaster();
  Group childred = Group();
  Camera camera;
  final Pointer _pointer = Pointer(0,0,4);
  PlaneType planeType = PlaneType.none;
  Object3D? _hovered;

  Object3D? get selectedPlane => _hovered;

  Origin(
    this.camera,
    this.listenableKey,
  ){
    childred.add(
      Mesh(         
        SphereGeometry(0.05,16,16),
        MeshPhongMaterial.fromMap({
          'color': 0xffffff,
        })
      )..name = 'o'
      ..userData['selected'] = false
    );
    
    childred.add(
      Line2(
        LineGeometry()
        ..setPositions(Float32Array.fromList([0,0,0,0.5,0,0])),
        LineMaterial.fromMap( {
          'linewidth': 4, // in world units with size attenuation, pixels otherwise
          'color': 0xff0000
        })
      )..name = 'x'
      ..userData['selected'] = false
    );
    childred.add(
      Line2(
        LineGeometry()
        ..setPositions(Float32Array.fromList([0,0,0,0,0.5,0])),
        LineMaterial.fromMap( {
          'linewidth': 4, // in world units with size attenuation, pixels otherwise
          'color': 0x00ff00
        })
      )
      ..name = 'y'
      ..userData['selected'] = false
    );
    childred.add(
      Line2(
        LineGeometry()
        ..setPositions(Float32Array.fromList([0,0,0,0,0,0.5])),
        LineMaterial.fromMap( {
          'linewidth': 4, // in world units with size attenuation, pixels otherwise
          'color': 0x0000ff
        })
      )..name = 'z'
      ..userData['selected'] = false
    );
    
    childred.add(
      Mesh(         
        PlaneGeometry(0.5,0.5),
        MeshPhongMaterial.fromMap({
          'color': 0xffff00,
          'side': DoubleSide,
          'transparent': true,
          'opacity': 0.5
        })
      )
      ..position.y = 0.3
      ..position.x = 0.3
      ..name = 'xy'
      ..userData['selected'] = false
    );
    childred.add(
      Mesh(         
        PlaneGeometry(0.5,0.5),
        MeshPhongMaterial.fromMap({
          'color': 0xff00ff,
          'side': DoubleSide,
          'transparent': true,
          'opacity': 0.5
        })
      )
      ..position.z = 0.3
      ..position.x = 0.3
      ..name = 'xz'
      ..rotateX(math.pi/2)
      ..userData['selected'] = false
    );
    childred.add(
      Mesh(         
        PlaneGeometry(0.5,0.5),
        MeshPhongMaterial.fromMap({
          'color': 0x00ffff,
          'side': DoubleSide,
          'transparent': true,
          'opacity': 0.5
        })
      )
      ..position.z = 0.3
      ..position.y = 0.3
      ..name = 'yz'
      ..rotateY(math.pi/2)
      ..userData['selected'] = false
    );

  
    activate();
  }

  void selectPlane(String? name){
    for(final o in childred.children){
      if(o.name == name){
        o.userData['selected'] = true;
        _hovered = o;
        _hovered?.material?.emissive = Color.fromHex32(0xffffff);
      }
      else{
        o.userData['selected'] = false;
        o.material?.emissive = Color.fromHex32(0x000000);
      }
    }
    if(name == 'xy'){
      planeType = PlaneType.xy;
    } 
    else if(name == 'xz'){
      planeType = PlaneType.xz;
    }
    else if(name == 'yz'){
      planeType = PlaneType.yz;
    }
    else{
      planeType = PlaneType.none;
      _hovered?.material?.emissive = Color.fromHex32(0x000000);
      _hovered = null;
    }
  }

  void onPointerDown(event) {
    getPointer(event);
    if(_pointer.button == 0){
      final iso = intersectObjectWithRay();
      if(iso == null){
        planeType = PlaneType.none;
        _hovered?.material?.emissive = Color.fromHex32(0x000000);
        _hovered = null;
      }
      else{
        selectPlane(iso.object?.name);
      }
    }
  }

  void onPointerHover(WebPointerEvent event) {
    getPointer(event);
    final iso = intersectObjectWithRay();
    if(selectedPlane == PlaneType.none){
      if(_hovered != null){
        _hovered?.material?.emissive = Color.fromHex32(0x000000);
        _hovered = null;
      }
      if(iso?.object?.name == 'xy' || iso?.object?.name == 'xz' || iso?.object?.name == 'yz'){
        _hovered = iso!.object;
        _hovered?.material?.emissive = Color.fromHex32(0xffffff);
      }
    }
  }
  void getPointer(WebPointerEvent event) {
    final RenderBox renderBox = listenableKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    double left = 0;
    double top = 0;

    final x_ = (event.clientX - left) / size.width * 2 - 1;
    final y_ = -(event.clientY - top) / size.height* 2 + 1.06;
    final button = event.button;

    _pointer.x  = x_;
    _pointer.y = y_;
    _pointer.button = button;
  }
  Intersection? intersectObjectWithRay() {
    _raycaster.setFromCamera(Vector2(_pointer.x, _pointer.y), camera);
    final all = _raycaster.intersectObjects(childred.children, true);
    if(all.isNotEmpty){
      return all[0];
    }

    return null;
  }

  /// Adds the event listeners of the controls.
  void activate() {
    _domElement.addEventListener(PeripheralType.pointerHover, onPointerHover);
    _domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
  }

  /// Removes the event listeners of the controls.
  void deactivate() {
    _domElement.removeEventListener(PeripheralType.pointerHover, onPointerHover);
    _domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
  }

  void dispose(){
    clearListeners();
  } 
}