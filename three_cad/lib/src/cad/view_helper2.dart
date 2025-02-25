import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:three_js_core/three_js_core.dart';

enum OffsetType {
  topLeft,
  bottomLeft,
  bottomRight,
  topRight,
  center
}

class ViewHelper extends Object3D{
  final bool isViewHelper = true;
  bool animating = false;
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

  late Camera camera;
  final orthoCamera = OrthographicCamera( - 2, 2, 2, - 2, 0, 4 );

  late final Vector2 _offset;
  final center = Vector3();
  final dummy = Object3D();
  late Size screenSize;

  final Vector2 _scissorPos = Vector2();
  Vector2? _pointerPos;
  OffsetType offsetType;
  final Raycaster _raycaster = Raycaster();
  final List<Object3D> interactiveObjects = [];
  final mouse = Vector2();

  final targetPosition = Vector3();
  final targetQuaternion = Quaternion();

  final q1 = Quaternion();
  final q2 = Quaternion();
  final viewport = Vector4();

  late final DirectionalLight light;

  double radius = 0;
  final point = Vector3();
  final turnRate = 2 * math.pi; // turn rate in angles per second

  ViewHelper({
    required this.camera, 
    required this.listenableKey, 
    required this.screenSize,
    Vector2? offset,
    this.offsetType = OffsetType.bottomLeft,
  }):super(){
    _offset = offset ?? Vector2();
    _calculatePosition();
    orthoCamera.position.setValues( 0, 0, 2 );
    createBox();
    _activate();
    addLight();
  }
  void addLight(){
    final ambientLight = AmbientLight( 0xffffff, 0.5 );
    add( ambientLight );

    light = DirectionalLight( 0xffffff, 0.7 );
    light.position = camera.position;
    add( light );
  }
  Mesh _createEdge(
    double x, 
    double y, 
    double z, 
    double th, 
    double ga, 
    double ep,
    int color
  ){
    
    return Mesh(
      BoxGeometry(0.025,0.65,0.025),
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
    ..userData['selected'] = false;
    
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
      Float32BufferAttribute.fromList(vertices, 3)
    );
    geom.setIndex(indices);
    geom.computeVertexNormals();

    return geom;
  }
  void createBox(){
    final m = MeshPhongMaterial.fromMap({
      'color': 0x999999,
    })..flatShading = true;
    final box = Mesh(facetedBox(1.8,1.8,1.8,0.2),m);
    add(box);
    interactiveObjects.add(box);
    Group g = Group();
    g.add(_createEdge(0.325, 0, 0, 0, 0, math.pi/2,0xff0000));
    g.add(_createEdge(0, 0.325, 0, 0, 0, 0,0x00ff00));
    g.add(_createEdge(0, 0, 0.325, math.pi/2, 0, 0,0x0000ff));
    add(g..scale.scale(3.25));
  }

  void _calculatePosition(){
    final RenderBox renderBox = listenableKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    if(offsetType == OffsetType.bottomLeft){
      _scissorPos.x = _offset.x;
      _scissorPos.y = _offset.y;
    }
    else if(offsetType == OffsetType.bottomRight){
      _scissorPos.x = size.width-(_offset.x+screenSize.width);
      _scissorPos.y = _offset.y;
    }
    else if(offsetType == OffsetType.topLeft){
      _scissorPos.x = _offset.x;
      _scissorPos.y = size.height-(_offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.topRight){
      _scissorPos.x = size.width-(_offset.x+screenSize.width);
      _scissorPos.y = size.height-(_offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.center){
      _scissorPos.x = (size.width/2-(screenSize.width)/2);//offset.x+
      _scissorPos.y = (size.height/2-(screenSize.height)/2);//offset.y+
    }
  }
  void _calculatePointerPosition(Size size){
    _pointerPos = Vector2();
    if(offsetType == OffsetType.bottomLeft){
      _pointerPos!.x = _offset.x;
      _pointerPos!.y = size.height-(_offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.bottomRight){
      _pointerPos!.x = size.width-(_offset.x+screenSize.width);
      _pointerPos!.y = size.height-(_offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.topLeft){
      _pointerPos!.x = _offset.x;
      _pointerPos!.y = _offset.y;//size.height-(offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.topRight){
      _pointerPos!.x = size.width-(_offset.x+screenSize.width);
      _pointerPos!.y = _offset.y;//size.height-(offset.y+screenSize.height);
    }
    else if(offsetType == OffsetType.center){
      _pointerPos!.x = (size.width/2-(screenSize.width)/2);//offset.x+
      _pointerPos!.y = (size.height/2-(screenSize.height)/2);//offset.y+
    }
  }
  void render(WebGLRenderer renderer){
    quaternion.setFrom( camera.quaternion ).invert();
    updateMatrixWorld();

    point.setValues( 0, 0, 1 );
    point.applyQuaternion( camera.quaternion );

    renderer.clearDepth();

    renderer.getViewport( viewport );
    renderer.setViewport( _scissorPos.width, _scissorPos.height, screenSize.width, screenSize.height );

    renderer.render( this, orthoCamera );
    renderer.setViewport( viewport.x, viewport.y, viewport.z, viewport.w );
  }
  bool handleClick(WebPointerEvent event ) {
    if(_pointerPos == null){
      final RenderBox renderBox = listenableKey.currentContext!.findRenderObject() as RenderBox;
      final size = renderBox.size;
      _calculatePointerPosition(size);
    }

    if (animating) return false;
    mouse.x = (event.clientX - _pointerPos!.x) / screenSize.width * 2 - 1;
    mouse.y  = -(event.clientY - _pointerPos!.y+2) / screenSize.height * 2 + 1;

    _raycaster.setFromCamera( mouse, orthoCamera );
    final intersects = _raycaster.intersectObjects( interactiveObjects, false );
    if ( intersects.isNotEmpty) {
      final intersection = intersects[ 0 ];
      prepareAnimationData(intersection.face, center);
      animating = true;
      return true;
    } 
    else {
      return false;
    }
  }
  void prepareAnimationData(Face? face, Vector3 focusPoint ) {
    if(face == null) return;
    targetPosition.setFrom(face.normal);

    radius = camera.position.distanceTo( focusPoint );
    targetPosition.scale( radius ).add( focusPoint );

    dummy.position.setFrom( focusPoint );

    dummy.lookAt( camera.position );
    q1.setFrom( dummy.quaternion );

    dummy.lookAt( targetPosition );
    q2.setFrom( dummy.quaternion );
  }

  void update( delta ) {
    final step = delta * turnRate;

    q1.rotateTowards( q2, step );
    camera.position.setValues( 0, 0, 1 )
      .applyQuaternion( q1 )
      .scale( radius )
      .add( center );
    camera.quaternion.rotateTowards( targetQuaternion, step );
    
    if(q1.angleTo( q2 ) > -0.0005 && q1.angleTo( q2 ) < 0.0005) {
      animating = false;
    }
  }
  /// Adds the event listeners of the controls.
  void _activate() {
    _domElement.addEventListener(PeripheralType.pointerdown, handleClick);
  }

  /// Removes the event listeners of the controls.
  void _deactivate() {
    _domElement.removeEventListener(PeripheralType.pointerdown, handleClick);
  }

  @override
  void dispose(){
    super.dispose();
    _deactivate();
  } 
}