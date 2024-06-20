import 'dart:math' as math;
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'spherical.dart';
import 'package:flutter/material.dart' hide Matrix4;

class ThirdPersonControls with EventDispatcher {

  /// [camera] - The camera to be controlled.
  /// 
  /// [listenableKey] - The element used for event listeners.
  ThirdPersonControls({
    required this.object,
    required this.camera,
    required this.listenableKey,
    Vector3? offset,
    this.movementSpeed = 1.0,
    this.onMouseDown,
    this.onMouseUp
  }):super(){
    this.offset = offset ?? Vector3.zero();
    if(onMouseDown != null){
      domElement.addEventListener( PeripheralType.pointerdown, onMouseDown!, false );
    }
    if(onMouseUp != null){
      domElement.addEventListener( PeripheralType.pointerup, onMouseUp!, false );
    }
    //this.domElement.setAttribute( 'tabindex', - 1 );
    domElement.addEventListener( PeripheralType.keydown, onKeyDown, false );
    domElement.addEventListener( PeripheralType.keyup, onKeyUp, false );

    handleResize();
	  setOrientation(this);
  }

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;

	Camera camera;
  Object3D object;

	bool enabled = true;
  bool clickMove = false;

	double movementSpeed = 1.0;
  Vector3 velocity = Vector3();

	bool heightSpeed = false;
	double heightCoef = 1.0;
	double heightMin = 0.0;
	double heightMax = 1.0;

	double autoSpeedFactor = 0.0;

	double mouseX = 0;
	double mouseY = 0;

	bool moveForward = false;
	bool moveBackward = false;
	bool moveLeft = false;
	bool moveRight = false;

	double viewHalfX = 0;
	double viewHalfY = 0;

	Vector3 lookDirection = Vector3();
  Vector3 offset = Vector3.zero();
	Spherical spherical = Spherical();
	Vector3 target = Vector3();
  Vector3 targetPosition = Vector3();
  double cameraAngle = 0;

	void Function(dynamic)? onMouseDown;
	void Function(dynamic)? onMouseUp;

  /// Should be called if the application window is resized.
	void handleResize(){
		viewHalfX = domElement.clientWidth / 2;
		viewHalfY = domElement.clientHeight / 2;
	}

  bool get isMoving => moveBackward || moveForward || moveLeft || moveRight;

	void onKeyDown(event) {
		switch ( event.keyId ) {
			case 4294968068: /*up*/
			case 119: /*W*/ 
        moveForward = true; 
        break;
			case 4294968066: /*left*/
			case 97: /*A*/ 
        moveLeft = true; 
        break;

			case 4294968065: /*down*/
			case 115: /*S*/ 
        moveBackward = true; 
        break;

			case 4294968067: /*right*/
			case 100: /*D*/ 
        moveRight = true; 
        break;
		}
	}

	void onKeyUp( event ) {
		switch ( event.keyId ) {
			case 4294968068: /*up*/
			case 119: /*W*/ 
        moveForward = false; 
        break;

			case 4294968066: /*left*/
			case 97: /*A*/ 
        moveLeft = false; 
        break;

			case 4294968065: /*down*/
			case 115: /*S*/ 
        moveBackward = false; 
        break;

			case 4294968067: /*right*/
			case 100: /*D*/ 
        moveRight = false; 
        break;
		}
	}

	ThirdPersonControls lookAt (Vector3 v) {
		target.setFrom(v).add(offset);
		camera.lookAt( target );
		setOrientation( this );
		return this;
	}
  Vector3 getForwardVector() {
    object.getWorldDirection(targetPosition);
    targetPosition.y = 0;
    targetPosition.normalize();
    return targetPosition;
  }

  /// Updates the controls. Usually called in the animation loop.
  void update(double delta){
    if(enabled == false) return;

    if(heightSpeed) {
      double y = MathUtils.clamp<double>(object.position.y, heightMin, heightMax );
      final heightDelta = y - heightMin;
      autoSpeedFactor = delta * (heightDelta * heightCoef);
    }
    else {
      autoSpeedFactor = 0.0;
    }

    double actualMoveSpeed = delta * movementSpeed;

    if(moveForward ){
      velocity.add( getForwardVector().scale(actualMoveSpeed));
    }
    if(moveBackward){
      velocity.add( getForwardVector().scale(-actualMoveSpeed));
    }
    if(moveLeft){
      object.rotation.y += movementSpeed*math.pi/180;
    }
    if(moveRight){
      object.rotation.y -= movementSpeed*math.pi/180;
    }

    object.position.setFrom(velocity);

    cameraAngle = (1-0.01)*cameraAngle+0.01*object.rotation.y;
    camera.position.setFromSphericalCoords( 15, 1, cameraAngle );
    camera.position.setFrom(object.position).add( offset );
    camera.lookAt( object.position );
  }

  /// Should be called if the controls is no longer required.
	void disconnect() {
    if(onMouseDown != null){
		  domElement.removeEventListener( PeripheralType.pointerdown, onMouseDown!, false );
    }
    if(onMouseUp != null){
		  domElement.removeEventListener( PeripheralType.pointerup, onMouseUp!, false );
    }

		domElement.removeEventListener( PeripheralType.keydown, onKeyDown, false );
		domElement.removeEventListener( PeripheralType.keyup, onKeyUp, false );
	}

  void dispose(){
    clearListeners();
  } 

	void setOrientation( controls ) {
		final quaternion = controls.camera.quaternion;

		lookDirection.setValues( 0, 0, - 1 ).applyQuaternion( quaternion );
		spherical.setFromVector3( lookDirection );
	}
}
