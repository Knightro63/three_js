import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:flutter/material.dart' hide Color;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_line/three_js_line.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

enum OriginTypes{
  none,xy,xz,yz,x,y,z,origin;

  static OriginTypes fromString(String? name){
    if(name == 'xy'){
      return OriginTypes.xy;
    } 
    else if(name == 'xz'){
      return OriginTypes.xz;
    }
    else if(name == 'yz'){
      return OriginTypes.yz;
    }
    else if(name == 'x'){
      return OriginTypes.x;
    }
    else if(name == 'y'){
      return OriginTypes.y;
    }
    else if(name == 'z'){
      return OriginTypes.z;
    }
    else if(name == 'o'){
      return OriginTypes.origin;
    }

    return OriginTypes.none;
  }

  static bool isGrid(String? name){
    if(name == 'xy'){
      return true;
    } 
    else if(name == 'xz'){
      return true;
    }
    else if(name == 'yz'){
      return true;
    }

    return false;
  }
}

class Origin with EventDispatcher{
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

  final Raycaster _raycaster = Raycaster();
  Group childred = Group();
  Camera camera;
  final Pointer _pointer = Pointer(0,0,4);
  OriginTypes planeType = OriginTypes.none;
  Object3D? _hovered;
  Vector2 offset = Vector2();

  Object3D? get selectedPlane => _hovered;
  late final GridHelper grid;
  bool showGrid = false;
  bool lockGrid = false;

  final double scale;
  void Function(Object3D? name)? state;

  Origin(
    this.camera,
    this.listenableKey,
    Vector2? offset,[
      this.scale = 0.5,
      this.state
    ]
  ){
    this.offset = offset ?? Vector2();
    childred.add(
      Mesh(         
        SphereGeometry(0.05,8,8),
        MeshPhongMaterial.fromMap({
          'color': 0xffffff,
          'transparent': true,
          'opacity': 0.5
        })
      )
      ..name = 'o'
      ..userData['selected'] = false
    );
    
    childred.add(
      Mesh(
        BoxGeometry(0.025,0.45,0.025),
        LineBasicMaterial.fromMap( {
          'color': 0xff0000
        })
      )
      ..position.x = 0.325
      ..rotateZ(math.pi/2)
      ..name = 'x'
      ..userData['selected'] = false
    );
    childred.add(
      Mesh(
        BoxGeometry(0.025,0.45,0.025),
        LineBasicMaterial.fromMap( {
          'color': 0x00ff00
        })
      )
      ..position.y = 0.325
      ..name = 'y'
      ..userData['selected'] = false
    );
    childred.add(
      Mesh(
        BoxGeometry(0.025,0.45,0.025),
        LineBasicMaterial.fromMap( {
          'color': 0x0000ff
        })
      )
      ..position.z = 0.325
      ..rotateX(math.pi/2)
      ..name = 'z'
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
    
    // childred.add(
    //   Mesh(         
    //     PlaneGeometry(0.5,0.5),
    //     MeshPhongMaterial.fromMap({
    //       'color': 0xffffff,
    //       'side': DoubleSide,
    //       'transparent': true,
    //       'opacity': 0.5
    //     })
    //   )
    //   ..position.z = 0.3
    //   ..position.y = 0.3
    //   ..position.x = 0.3
    //   ..name = 'reset'
    //   ..visible = false
    //   ..rotateY(-math.pi/4)
    //   ..rotateX(-math.pi/2)
    //   ..rotateZ(-math.pi/2)
    //   ..userData['selected'] = false
    // );
    //childred.scale.setValues(scale,scale,scale);
    createGrid();
    activate();
  }

  void createGrid(){
    grid = GridHelper( 20, 200, Colors.grey[900]!.value, Colors.grey[900]!.value);
    grid.visible = showGrid;
    grid.frustumCulled = false;

    grid.add(
      LineSegments(
        BufferGeometry()
        ..setAttributeFromString('position',Float32BufferAttribute.fromList([10,0,0,-10,0,0], 3, false)),
        LineBasicMaterial.fromMap({
          "color": 0xff0000
        })
          ..depthTest = false
          ..linewidth = 5.0
          ..depthWrite = true
      )
      ..name = 'x'
      ..computeLineDistances()
      ..scale.setValues(1,1,1)
    );
    grid.add(
      LineSegments(
        BufferGeometry()
        ..setAttributeFromString('position',Float32BufferAttribute.fromList([0,0,10,0,0,-10], 3, false)),
        LineBasicMaterial.fromMap({
          "color": 0x0000ff
        })
          ..depthTest = false
          ..linewidth = 5.0
          ..depthWrite = true
      )
      ..name = 'x'
      ..computeLineDistances()
      ..scale.setValues(1,1,1)
    );
  }
  void setHighlight(Object3D? object){
    object?.material?.emissive = Color.fromHex32(0xffffff);
    object?.material?.opacity = 1.0;
    state?.call(object);
  }
  void clearHighlight(Object3D? object){
    object?.material?.emissive = Color.fromHex32(0x000000);
    object?.material?.opacity = 0.5;
    state?.call(object);
  }
  void selectPlane(String? name){
    for(final o in childred.children){
      if(o.name == name){
        o.userData['selected'] = true;
        _hovered = o;
        setHighlight(_hovered);
      }
      else{
        o.userData['selected'] = false;
        clearHighlight(o);
      }
    }

    planeType = OriginTypes.fromString(name);
    if(planeType == OriginTypes.none){
      planeType = OriginTypes.none;
      clearHighlight(_hovered);
      _hovered = null;
    }
  }

  void gridHover(String? name){
    if(showGrid){
      grid.visible = true;
      if(name == 'xy'){
        grid.position.setValues(0,0,0);
        grid.lookAt(Vector3(0, math.pi, 0));

        grid.children[0].material?.color = Color.fromHex32(0xff0000);
        grid.children[1].material?.color = Color.fromHex32(0x00ff00);
      } 
      else if(name == 'xz'){
        grid.position.setValues(0,0,0);
        grid.lookAt(Vector3(0, 0, 0));

        grid.children[0].material?.color = Color.fromHex32(0xff0000);
        grid.children[1].material?.color = Color.fromHex32(0x0000ff);
      }
      else if(name == 'yz'){
        grid.position.setValues(0,0,0);
        grid.lookAt(Vector3(0,1, 0));
        grid.rotateZ(math.pi/2);
        grid.updateMatrixWorld();

        grid.children[1].material?.color = Color.fromHex32(0x00ff00);
        grid.children[0].material?.color = Color.fromHex32(0x0000ff);
      }
    }else{
      grid.visible = false;
    }
  }

  void onPointerDown(event) {
    getPointer(event);
    if(_pointer.button == 0){
      final iso = intersectObjectWithRay();
      if(iso == null){
        planeType = OriginTypes.none;
        clearHighlight(_hovered);
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
    if(planeType == OriginTypes.none){
      if(_hovered != null){
        clearHighlight(_hovered);
        _hovered = null;
      }
      if(OriginTypes.fromString( iso?.object?.name) != OriginTypes.none){
        _hovered = iso!.object;
        setHighlight(_hovered);
      }
    }

    if((OriginTypes.isGrid(iso?.object?.name)) && childred.visible){
      gridHover(iso?.object?.name);
    }
    else if(!lockGrid){
      grid.visible = false;
    }
  }
  void getPointer(WebPointerEvent event) {
    final RenderBox renderBox = listenableKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final x_ = (event.clientX + offset.x) / size.width * 2 - 1;
    final y_ = -(event.clientY + offset.y) / size.height* 2 + 1.06;
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

  void update(){
    childred.scale.setValues(scale/camera.zoom, scale/camera.zoom, scale/camera.zoom);
  }
}