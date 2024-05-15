import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter/material.dart' hide Matrix4;

class FlyMoveState{
  double up = 0; 
  double down =  0; 
  double left =  0; 
  double right =  0; 
  double forward =  0; 
  double back =  0; 
  double pitchUp =  0; 
  double pitchDown =  0; 
  double yawLeft =  0; 
  double yawRight =  0; 
  double rollLeft =  0; 
  double rollRight =  0;
}

class _ContainerDimensions{
  _ContainerDimensions({
    required this.size,
    required this.offset
  });
  Size size;
  Offset offset;
}

/// [FlyControls] enables a navigation similar to fly modes in DCC tools like Blender. You can arbitrarily transform the camera in
/// 3D space without any limitations (e.g. focus on a specific target).
class FlyControls{
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;
	Camera object;

  /// [object] - The camera to be controlled.
  /// 
  /// [listenableKey] - The element used for event listeners.
  FlyControls(this.object, this.listenableKey ) {
    //if(domElement) this.domElement.setAttribute( 'tabindex', - 1 );

    domElement.addEventListener( PeripheralType.contextmenu, contextmenu, false );
    domElement.addEventListener( PeripheralType.pointermove, mousemove, false );
    domElement.addEventListener( PeripheralType.pointerdown, mousedown, false );
    domElement.addEventListener( PeripheralType.pointerup, mouseup, false );
    domElement.addEventListener( PeripheralType.keydown, keydown, false );
    domElement.addEventListener(PeripheralType.keyup, keyup, false );

    updateMovementVector();
    updateRotationVector();
  }

	double movementSpeed = 1.0;
  double movementSpeedMultiplier = 1.0;
	double rollSpeed = 0.005;
	bool dragToLook = false;
	bool autoForward = false;

	//var changeEvent = {type: 'change' };
	double eps = 0.000001;

	Quaternion tmpQuaternion = Quaternion.identity();

	int mouseStatus = 0;

	FlyMoveState moveState = FlyMoveState();
	Vector3 moveVector = Vector3( 0, 0, 0 );
	Vector3 rotationVector = Vector3( 0, 0, 0 );

	void keydown ( event ) {
    event as LogicalKeyboardKey;
		if ( event.keyLabel.contains('alt') ) {
			return;
		}

		//event.preventDefault();

		switch ( event.keyLabel.toLowerCase() ) {
      case 'shift right':
			case 'shift left': /* shift */ movementSpeedMultiplier = .1; break;

			case 'w': /*W*/ moveState.forward = 1; break;
			case 's': /*S*/ moveState.back = 1; break;

			case 'a': /*A*/ moveState.left = 1; break;
			case 'd': /*D*/ moveState.right = 1; break;

			case 'r': /*R*/ moveState.up = 1; break;
			case 'f': /*F*/ moveState.down = 1; break;

			case 'arrow up': /*up*/ moveState.pitchUp = 1; break;
			case 'arrow down': /*down*/ moveState.pitchDown = 1; break;

			case 'arrow left': /*left*/ moveState.yawLeft = 1; break;
			case 'arrow right': /*right*/ moveState.yawRight = 1; break;

			case 'q': /*Q*/ moveState.rollLeft = 1; break;
			case 'e': /*E*/ moveState.rollRight = 1; break;

		}

		updateMovementVector();
		updateRotationVector();
	}

	void keyup( event ) {
    event as LogicalKeyboardKey;
		switch ( event.keyLabel.toLowerCase()) {
      case 'shift right':
			case 'shift left': /* shift */ movementSpeedMultiplier = 1; break;

			case 'w': /*W*/ moveState.forward = 0; break;
			case 's': /*S*/ moveState.back = 0; break;

			case 'a': /*A*/ moveState.left = 0; break;
			case 'd': /*D*/ moveState.right = 0; break;

			case 'r': /*R*/ moveState.up = 0; break;
			case 'f': /*F*/ moveState.down = 0; break;

			case 'arrow up': /*up*/ moveState.pitchUp = 0; break;
			case 'arrow down': /*down*/moveState.pitchDown = 0; break;

			case 'arrow left': /*left*/ moveState.yawLeft = 0; break;
			case 'arrow right': /*right*/ moveState.yawRight = 0; break;

			case 'q': /*Q*/ moveState.rollLeft = 0; break;
			case 'e': /*E*/ moveState.rollRight = 0; break;
		}

		updateMovementVector();
		updateRotationVector();
	}

  void mousedown( event ) {
		event.preventDefault();
		event.stopPropagation();

		if (dragToLook ) {
			mouseStatus ++;
		} 
    else {
			switch ( event.button ) {
				case 0: moveState.forward = 1; break;
				case 2: moveState.back = 1; break;
			}

			updateMovementVector();
		}
	}

	void mousemove( event ) {
		if (!dragToLook || mouseStatus > 0 ) {
			var container = _getContainerDimensions();
			var halfWidth = container.size.width / 2;
			var halfHeight = container.size.height / 2;

			moveState.yawLeft = - ( ( event.pageX - container.offset.dx ) - halfWidth ) / halfWidth;
			moveState.pitchDown = ( ( event.pageY - container.offset.dy ) - halfHeight ) / halfHeight;

			updateRotationVector();
		}
	}

	void mouseup( event ) {
		event.preventDefault();
		event.stopPropagation();

		if (dragToLook ) {
			mouseStatus --;
			moveState.yawLeft = moveState.pitchDown = 0;
		} 
    else {
			switch ( event.button ) {
				case 0: moveState.forward = 0; break;
				case 2: moveState.back = 0; break;
			}

			updateMovementVector();
		}

		updateRotationVector();
	}

  final _lastQuaternion = Quaternion();
  final _lastPosition = Vector3();
  //double delta = 1;

  /// Updates the controls. Usually called in the animation loop.
	void update(double delta) {
    final moveMult = delta * movementSpeed;
    final rotMult = delta * rollSpeed;

    object.translateX( moveVector.x * moveMult );
    object.translateY( moveVector.y * moveMult );
    object.translateZ( moveVector.z * moveMult );

    tmpQuaternion.set( rotationVector.x * rotMult, rotationVector.y * rotMult, rotationVector.z * rotMult, 1 ).normalize();
    object.quaternion.multiply( tmpQuaternion );

    if (
      _lastPosition.distanceToSquared( object.position ) > eps ||
      8 * ( 1 - _lastQuaternion.dot( object.quaternion ) ) > eps
    ) {

      // dispatchEvent( changeEvent );
      _lastQuaternion.setFrom( object.quaternion );
      _lastPosition.setFrom( object.position );

    }
	}

	void updateMovementVector() {
		final forward = (moveState.forward > 0 || (autoForward && moveState.back == 0)) ? 1 : 0;

		moveVector.x = ( - moveState.left + moveState.right );
		moveVector.y = ( - moveState.down + moveState.up );
		moveVector.z = ( - forward + moveState.back );
	}

	void updateRotationVector () {
		rotationVector.x = ( - moveState.pitchDown + moveState.pitchUp );
		rotationVector.y = ( - moveState.yawRight + moveState.yawLeft );
		rotationVector.z = ( - moveState.rollRight + moveState.rollLeft );
	}

	_ContainerDimensions _getContainerDimensions () {
		// if ( this.domElement != document ) {
			return _ContainerDimensions(
				size: Size(domElement.clientWidth, domElement.clientHeight),
				offset: Offset(domElement.offsetLeft, domElement.offsetTop)
      );
		// }
    // else {
		// 	return _ContainerDimensions(
		// 		size: Size(window.innerWidth, window.innerHeight),
		// 		offset: Offset(0,0,)
    //   );
		// }
	}

	void contextmenu( event ) {
		event.preventDefault();
	}

  /// Should be called if the controls is no longer required.
	void dispose(){
		domElement.removeEventListener( PeripheralType.contextmenu, contextmenu, false );
		domElement.removeEventListener( PeripheralType.pointerdown, mousedown, false );
		domElement.removeEventListener( PeripheralType.pointerHover, mousemove, false );
		domElement.removeEventListener( PeripheralType.pointerup, mouseup, false );
		domElement.removeEventListener( PeripheralType.keydown, keydown, false );
		domElement.removeEventListener( PeripheralType.keyup, keyup, false );
	}
}
