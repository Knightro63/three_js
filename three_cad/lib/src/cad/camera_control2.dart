import 'dart:math' as math;
import 'package:three_js/three_js.dart';
import 'package:flutter/material.dart' hide Material;
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
  final Group _controls = Group();

  late final DirectionalLight light;

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
    createBox();

    double f = 1;

    camera = OrthographicCamera( - f,f,f,-f, 0.05, 50 );
    camera.quaternion = rotationCamera.quaternion;
    _controls.scale.setValues( size*f,size*f,size*f );
    
    scene.add(_controls);
    scene.onAfterRender = ({Camera? camera, BufferGeometry? geometry, Map<String, dynamic>? group, Material? material, WebGLRenderer? renderer, Object3D? scene}){
      final pLocal = Vector3( 0, 0, -2 );
      final pWorld = pLocal.applyMatrix4( this.camera.matrixWorld );
      pWorld.sub(this.camera.position ).normalize();
      _controls.position.setFrom(pWorld);
      light.position.setFrom(threeJs.camera.position);
    };

    activate();
    addLight();
  }

  void addLight(){
    final ambientLight = AmbientLight( 0xffffff, 0.5 );
    scene.add( ambientLight );

    light = DirectionalLight( 0xffffff, 0.7 );
    //light.position = camera.position;
    scene.add( light );
  }
    void _createEdge(
    double x, 
    double y, 
    double z, 
    double th, 
    double ga, 
    double ep,
    int color
  ){
    _controls.add(
      Mesh(
        BoxGeometry(0.025,0.3,0.025),
        LineBasicMaterial.fromMap( {
          'color': color
        })
      )
      ..position.x = x-0.3
      ..position.y = y-0.3
      ..position.z = z-0.3
      ..rotateX(th)
      ..rotateY(ga)
      ..rotateZ(ep)
      ..userData['selected'] = false
    );
  }
  void _createFace(
    double x, 
    double y, 
    double z, 
    double th, 
    double ga, 
    double ep,
    int color
  ){
    _controls.add(
      Mesh(         
        PlaneGeometry(0.4,0.4),
        MeshBasicMaterial.fromMap({
          'color': color,
          'side': DoubleSide,
        })
      )
      ..position.x = x-0.32
      ..position.y = y-0.32
      ..position.z = z-0.32
      ..rotateX(th)
      ..rotateY(ga)
      ..rotateZ(ep)
    );
  }
  BufferGeometry facetedBox(double w,double h,double d,double f){
    final hw = w * 0.5, 
    hh = h * 0.5, 
    hd = d * 0.5;

    final List<double> vertices = [
      // px
      hw, hh - f, -hd + f,   // 0
      hw, -hh + f, -hd + f,  // 1
      hw, -hh + f, hd - f,   // 2
      hw, hh - f, hd - f,    // 3
      
      // pz
      hw - f, hh - f, hd,    // 4
      hw - f, -hh + f, hd,   // 5
      -hw + f, -hh + f, hd,  // 6
      -hw + f, hh - f, hd,   // 7
      
      // nx
      -hw, hh - f, hd - f,   // 8
      -hw, -hh + f, hd - f,  // 9
      -hw, -hh + f, -hd + f, // 10
      -hw, hh - f, -hd + f,  // 11
      
      // nz
      -hw + f, hh - f, -hd,  // 12
      -hw + f, -hh + f, -hd, // 13
      hw - f, -hh + f, -hd,  // 14
      hw - f, hh - f, -hd,   // 15
      
      // py
      hw - f, hh, -hd + f,   // 16
      hw - f, hh, hd - f,    // 17
      -hw + f, hh, hd - f,   // 18
      -hw + f, hh, -hd + f,  // 19
      
      // ny
      hw - f, -hh, -hd + f,  // 20
      hw - f, -hh, hd - f,   // 21
      -hw + f, -hh, hd - f,  // 22
      -hw + f, -hh, -hd + f  // 23
    ];
    
    final indices = [
      0, 2, 1, 3, 2, 0,
      4, 6, 5, 7, 6, 4,
      8, 10, 9, 11, 10, 8,
      12, 14, 13, 15, 14, 12,
      16, 18, 17, 19, 18, 16,
      20, 21, 22, 23, 20, 22,
      
      // link the sides
      3, 5, 2, 4, 5, 3,
      7, 9, 6, 8, 9, 7,
      11, 13, 10, 12, 13, 11,
      15, 1, 14, 0, 1, 15,
      
      // link the lids
      // top
      16, 3, 0, 17, 3, 16,
      17, 7, 4, 18, 7, 17,
      18, 11, 8, 19, 11, 18,
      19, 15, 12, 16, 15, 19,
      // bottom
      1, 21, 20, 2, 21, 1,
      5, 22, 21, 6, 22, 5,
      9, 23, 22, 10, 23, 9,
      13, 20, 23, 14, 20, 13,
      
      // corners
      // top
      3, 17, 4,
      7, 18, 8,
      11, 19, 12,
      15, 16, 0,
      // bottom
      2, 5, 21,
      6, 9, 22,
      10, 13, 23,
      14, 1, 20
    ];
    
    final geom = BufferGeometry();
    geom.setAttributeFromString(
      "position", 
      Float32BufferAttribute(Float32Array.fromList(vertices), 3)
    );
    geom.setIndex(indices);
    geom.computeVertexNormals();

    return geom;
  }
  void createBox(){
    final m = MeshPhongMaterial.fromMap({
      'color': 0x999999,
    })..flatShading = true;
  
    _controls.add(Mesh(facetedBox(0.6,0.6,0.6,0.06),m));

    // _controls.add(
    //   Mesh(         
    //     SphereGeometry(0.05,8,8),
    //     MeshPhongMaterial.fromMap({
    //       'color': 0xffffff,
    //       'transparent': true,
    //       //'opacity': 0.5
    //     })
    //   )
    //   ..position.x = 0-0.3
    //   ..position.y = 0-0.3
    //   ..position.z = 0-0.3
    //   ..name = 'o'
    //   ..userData['selected'] = false
    // );

    _createEdge(0.15, 0, 0, 0, 0, math.pi/2,0xff0000);
    _createEdge(0, 0.15, 0, 0, 0, 0,0x00ff00);
    _createEdge(0, 0, 0.15, math.pi/2, 0, 0,0x0000ff);

    // _createFace(0.25, 0.25, 0, 0,0,0, 0xffff00);
    // _createFace(0.25, 0 ,0.25, math.pi/2,0,0, 0xff00ff);
    // _createFace(0, 0.25, 0.25, 0,math.pi/2,0, 0x00ffff);
  }

  void _calculatePosition(){
    if(offsetType == OffsetType.bottomLeft){
      _scissorPos.x = offset.x;
      _scissorPos.y = offset.y;
    }
    else if(offsetType == OffsetType.bottomRight){
      _scissorPos.x = threeJs.width-(offset.x+screenSize.width);
      _scissorPos.y = offset.y;
    }
    else if(offsetType == OffsetType.topLeft){
      _scissorPos.x = offset.x;
      _scissorPos.y = threeJs.height-(offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.topRight){
      _scissorPos.x = threeJs.width-(offset.x+screenSize.width);
      _scissorPos.y = threeJs.height-(offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.center){
      _scissorPos.x = (threeJs.width/2-(screenSize.width)/2);//offset.x+
      _scissorPos.y = (threeJs.height/2-(screenSize.height)/2);//offset.y+
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
    threeJs.renderer?.setScissor( _scissorPos.x, _scissorPos.y, screenSize.width, screenSize.height );
    threeJs.renderer?.setViewport( _scissorPos.x, _scissorPos.y, screenSize.width, screenSize.height );
    threeJs.renderer!.render(scene, camera);
    threeJs.renderer?.setScissorTest( false );
  }
  void onPointerDown(WebPointerEvent event) {
    final i = intersectObjectWithRay(event);

    if(i?.face != null){
      final pLocal = Vector3.copy(i!.face!.normal.clone().scale(5));
      threeJs.camera.position.setFrom(pLocal);
      threeJs.camera.lookAt(i.face!.normal);
    }
  }
  void onPointerHover(WebPointerEvent event) {
    final i = intersectObjectWithRay(event);

    if(i?.face != null){        

    }
  }
  Pointer? getPointer(WebPointerEvent event) {
    if(event.button == 0){
      final RenderBox renderBox = listenableKey.currentContext!.findRenderObject() as RenderBox;
      final size = renderBox.size;

      if(_pointerPos == null){
        _calculatePointerPosition(size);
      }

      final x_ = (event.clientX - _pointerPos!.x) / screenSize.width * 2 - 1;
      final y_ = -(event.clientY - _pointerPos!.y+2) / screenSize.height * 2 + 1;
      final button = event.button;
      return Pointer(x_, y_, button);
    }
    return null;
  }
  Intersection? intersectObjectWithRay(WebPointerEvent event) {
    final pointer = getPointer(event);
    if(pointer != null){
      _raycaster.setFromCamera(Vector2(pointer.x, pointer.y), camera);
      final all = _raycaster.intersectObjects(_controls.children, false);
      if(all.isNotEmpty){
        return all[0];
      }
    }
    return null;
  }

  /// Adds the event listeners of the controls.
  void activate() {
    _domElement.addEventListener(PeripheralType.pointermove, onPointerHover);
    _domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
  }

  /// Removes the event listeners of the controls.
  void deactivate() {
    _domElement.removeEventListener(PeripheralType.pointermove, onPointerHover);
    _domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
  }

  void dispose(){
    clearListeners();
  } 
}