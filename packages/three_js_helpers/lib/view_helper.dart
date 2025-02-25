import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

enum OffsetType {
  topLeft,
  bottomLeft,
  bottomRight,
  topRight,
  center
}

class ViewHelper extends Object3D {
  final bool isViewHelper = true;
  bool animating = false;
  final center = Vector3();

  final color1 = Color.fromHex32(0xff3653);
  final color2 = Color.fromHex32(0x8adb00);
  final color3 = Color.fromHex32(0x2c8fff);

  final List<Object3D> interactiveObjects = [];
  final raycaster = Raycaster();
  final mouse = Vector2();
  final dummy = Object3D();

  final orthoCamera = OrthographicCamera( - 2, 2, 2, - 2, 0, 4 );

  late final Mesh xAxis;
  late final Mesh yAxis;
  late final Mesh zAxis;

  final Camera camera;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;

  final targetPosition = Vector3();
  final targetQuaternion = Quaternion();

  final q1 = Quaternion();
  final q2 = Quaternion();
  final viewport = Vector4();

  double radius = 0;
  final point = Vector3();
  final turnRate = 2 * math.pi; // turn rate in angles per second

  final BoxGeometry geometry = BoxGeometry( 0.8, 0.05, 0.05 )..translate( 0.4, 0, 0 );

  late final Object3D posXAxisHelper;
  late final Object3D posYAxisHelper;
  late final Object3D posZAxisHelper;
  late final Object3D negXAxisHelper;
  late final Object3D negYAxisHelper;
  late final Object3D negZAxisHelper;

  Size screenSize;
  OffsetType offsetType;
  late final Vector2 _offset;
  Vector2? _pointerPos;
  final Vector2 _scissorPos = Vector2();

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
		xAxis = Mesh( geometry, getAxisMaterial( color1 ) );
		yAxis = Mesh( geometry, getAxisMaterial( color2 ) );
		zAxis = Mesh( geometry, getAxisMaterial( color3 ) );

		yAxis.rotation.z = math.pi / 2;
		zAxis.rotation.y = - math.pi / 2;

		add( xAxis );
		add( zAxis );
		add( yAxis );

		posXAxisHelper = Mesh(SphereGeometry(0.2),MeshBasicMaterial.fromMap({'color': color1}));//Sprite( getSpriteMaterial( color1, 'X' ) );
		posXAxisHelper.userData['type'] = 'posX';
		posYAxisHelper = Mesh(SphereGeometry(0.2),MeshBasicMaterial.fromMap({'color': color2}));//Sprite( getSpriteMaterial( color2, 'Y' ) );
		posYAxisHelper.userData['type'] = 'posY';
		posZAxisHelper = Mesh(SphereGeometry(0.2),MeshBasicMaterial.fromMap({'color': color3}));//Sprite( getSpriteMaterial( color3, 'Z' ) );
		posZAxisHelper.userData['type'] = 'posZ';
		negXAxisHelper = Mesh(SphereGeometry(0.2),MeshBasicMaterial.fromMap({'color': color1}));//Sprite( getSpriteMaterial( color1 ) );
		negXAxisHelper.userData['type'] = 'negX';
		negYAxisHelper = Mesh(SphereGeometry(0.2),MeshBasicMaterial.fromMap({'color': color2}));//Sprite( getSpriteMaterial( color2 ) );
		negYAxisHelper.userData['type'] = 'negY';
		negZAxisHelper = Mesh(SphereGeometry(0.2),MeshBasicMaterial.fromMap({'color': color3}));//Sprite( getSpriteMaterial( color3 ) );
		negZAxisHelper.userData['type'] = 'negZ';

		posXAxisHelper.position.x = 1;
		posYAxisHelper.position.y = 1;
		posZAxisHelper.position.z = 1;
		negXAxisHelper.position.x = - 1;
		negXAxisHelper.scale.setScalar( 0.8 );
		negYAxisHelper.position.y = - 1;
		negYAxisHelper.scale.setScalar( 0.8 );
		negZAxisHelper.position.z = - 1;
		negZAxisHelper.scale.setScalar( 0.8 );

		add( posXAxisHelper );
		add( posYAxisHelper );
		add( posZAxisHelper );
		add( negXAxisHelper );
		add( negYAxisHelper );
		add( negZAxisHelper );

		interactiveObjects.add( posXAxisHelper );
		interactiveObjects.add( posYAxisHelper );
		interactiveObjects.add( posZAxisHelper );
		interactiveObjects.add( negXAxisHelper );
		interactiveObjects.add( negYAxisHelper );
		interactiveObjects.add( negZAxisHelper );

    _activate();
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
  void render(WebGLRenderer renderer) {
    quaternion.setFrom( camera.quaternion ).invert();
    updateMatrixWorld();

    point.setValues( 0, 0, 1 );
    point.applyQuaternion( camera.quaternion );

    if ( point.x >= 0 ) {
      posXAxisHelper.material?.opacity = 1;
      negXAxisHelper.material?.opacity = 0.5;
    } else {
      posXAxisHelper.material?.opacity = 0.5;
      negXAxisHelper.material?.opacity = 1;
    }

    if ( point.y >= 0 ) {
      posYAxisHelper.material?.opacity = 1;
      negYAxisHelper.material?.opacity = 0.5;
    } else {
      posYAxisHelper.material?.opacity = 0.5;
      negYAxisHelper.material?.opacity = 1;
    }

    if ( point.z >= 0 ) {
      posZAxisHelper.material?.opacity = 1;
      negZAxisHelper.material?.opacity = 0.5;
    } else {
      posZAxisHelper.material?.opacity = 0.5;
      negZAxisHelper.material?.opacity = 1;
    }

    renderer.clearDepth();

    renderer.getViewport( viewport );
    renderer.setViewport( _scissorPos.width, _scissorPos.height, screenSize.width, screenSize.height );

    renderer.render( this, orthoCamera );
    renderer.setViewport( viewport.x, viewport.y, viewport.z, viewport.w );
  }

  void prepareAnimationData(Object3D? object, Vector3 focusPoint ) {
    switch (object?.userData['type']) {
      case 'posX':
        targetPosition.setValues( 1, 0, 0 );
        targetQuaternion.setFromEuler( Euler( 0, math.pi * 0.5, 0 ) );
        break;
      case 'posY':
        targetPosition.setValues( 0, 1, 0 );
        targetQuaternion.setFromEuler( Euler( - math.pi * 0.5, 0, 0 ) );
        break;
      case 'posZ':
        targetPosition.setValues( 0, 0, 1 );
        targetQuaternion.setFromEuler( Euler() );
        break;
      case 'negX':
        targetPosition.setValues( - 1, 0, 0 );
        targetQuaternion.setFromEuler( Euler( 0, - math.pi * 0.5, 0 ) );
        break;
      case 'negY':
        targetPosition.setValues( 0, - 1, 0 );
        targetQuaternion.setFromEuler( Euler( math.pi * 0.5, 0, 0 ) );
        break;
      case 'negZ':
        targetPosition.setValues( 0, 0, - 1 );
        targetQuaternion.setFromEuler( Euler( 0, math.pi, 0 ) );
        break;
      default:
        console.error( 'ViewHelper: Invalid axis.' );
    }
    
    radius = camera.position.distanceTo( focusPoint );
    targetPosition.scale( radius ).add( focusPoint );

    dummy.position.setFrom( focusPoint );

    dummy.lookAt( camera.position );
    q1.setFrom( dummy.quaternion );

    dummy.lookAt( targetPosition );
    q2.setFrom( dummy.quaternion );
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

  bool handleClick(WebPointerEvent event ) {
    if(_pointerPos == null){
      final RenderBox renderBox = listenableKey.currentContext!.findRenderObject() as RenderBox;
      final size = renderBox.size;
      _calculatePointerPosition(size);
    }

    if (animating) return false;
    mouse.x = (event.clientX - _pointerPos!.x) / screenSize.width * 2 - 1;
    mouse.y  = -(event.clientY - _pointerPos!.y+2) / screenSize.height * 2 + 1;

    raycaster.setFromCamera( mouse, orthoCamera );
    final intersects = raycaster.intersectObjects( interactiveObjects, false );
    if ( intersects.isNotEmpty) {
      final intersection = intersects[ 0 ];
      final object = intersection.object;
      prepareAnimationData( object, center );
      animating = true;
      return true;
    } 
    else {
      return false;
    }
  }

  void update( delta ) {
    final step = delta * turnRate;

    q1.rotateTowards( q2, step );
    camera.position.setValues( 0, 0, 1 ).applyQuaternion( q1 ).scale( radius ).add( center );
    camera.quaternion.rotateTowards( targetQuaternion, step );

    if ( q1.angleTo( q2 ) == 0 ) {
      animating = false;
    }
  }

  MeshBasicMaterial getAxisMaterial(Color color ) {
    return MeshBasicMaterial.fromMap( { 'color': color, 'toneMapped': false } );
  }

  // SpriteMaterial getSpriteMaterial(Color color,[String? text]) {
  //   final canvas = document.createElement( 'canvas' );
  //   canvas.width = 64;
  //   canvas.height = 64;

  //   final context = canvas.getContext( '2d' );
  //   context.beginPath();
  //   context.arc( 32, 32, 16, 0, 2 * math.pi );
  //   context.closePath();
  //   context.fillStyle = color.getStyle();
  //   context.fill();

  //   if ( text != null ) {
  //     context.font = '24px Arial';
  //     context.textAlign = 'center';
  //     context.fillStyle = '#000000';
  //     context.fillText( text, 32, 41 );
  //   }

  //   final texture = CanvasTexture( canvas );
  //   return SpriteMaterial.fromMap( { 'map': texture, 'toneMapped': false } );
  // }

  @override
  void dispose() {
    super.dispose();
    geometry.dispose();

    xAxis.material?.dispose();
    yAxis.material?.dispose();
    zAxis.material?.dispose();

    posXAxisHelper.material?.map?.dispose();
    posYAxisHelper.material?.map?.dispose();
    posZAxisHelper.material?.map?.dispose();
    negXAxisHelper.material?.map?.dispose();
    negYAxisHelper.material?.map?.dispose();
    negZAxisHelper.material?.map?.dispose();

    posXAxisHelper.material?.dispose();
    posYAxisHelper.material?.dispose();
    posZAxisHelper.material?.dispose();
    negXAxisHelper.material?.dispose();
    negYAxisHelper.material?.dispose();
    negZAxisHelper.material?.dispose();

    _deactivate();
  }

  /// Adds the event listeners of the controls.
  void _activate() {
    _domElement.addEventListener(PeripheralType.pointerdown, handleClick);
  }

  /// Removes the event listeners of the controls.
  void _deactivate() {
    _domElement.removeEventListener(PeripheralType.pointerdown, handleClick);
  }
}
