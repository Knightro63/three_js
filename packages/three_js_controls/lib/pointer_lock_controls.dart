import 'dart:math' as math;
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter/material.dart' hide Matrix4;

/// The implementation of this class is based on the [Pointer Lock API](https://developer.mozilla.org/en-US/docs/Web/API/Pointer_Lock_API).
/// [PointerLockControls] is a perfect choice for first person 3D games.
class PointerLockControls with EventDispatcher {
  final _changeEvent = Event(type: 'change');
  final _euler = Euler(0, 0, 0, RotationOrders.yxz);
  final _vector = Vector3.zero();
  final _lockEvent = Event(type: 'lock');
  final _unlockEvent = Event(type: 'unlock');

  final _pi2 = math.pi / 2;
  bool isLocked = false;

  // Set to constrain the pitch of the camera
  // Range is 0 to math.pi radians
  double minPolarAngle = 0; // radians
  double maxPolarAngle = math.pi; // radians

  double pointerSpeed = 1.0;

  late Camera camera;
  late PointerLockControls scope;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;

  /// [camera] - The camera to be controlled.
  /// 
  /// [listenableKey] - The element used for event listeners.
  PointerLockControls(this.camera, this.listenableKey) : super() {
    scope = this;
    connect();
  }

  void onMouseMove(event) {
    event as WebPointerEvent;
    if (scope.isLocked == false) return;

    final movementX = event.movementX;
    final movementY = event.movementY;

    _euler.setFromQuaternion(camera.quaternion);

    _euler.y -= movementX * 0.002 * scope.pointerSpeed;
    _euler.x -= movementY * 0.002 * scope.pointerSpeed;

    _euler.x = math.max(_pi2 - scope.maxPolarAngle,
        math.min(_pi2 - scope.minPolarAngle, _euler.x));

    camera.quaternion.setFromEuler(_euler);

    scope.dispatchEvent(_changeEvent);
  }

  void onPointerlockChange() {
    if (scope.domElement.pointerLockElement == scope.domElement) {
      scope.dispatchEvent(_lockEvent);

      scope.isLocked = true;
    } else {
      scope.dispatchEvent(_unlockEvent);

      scope.isLocked = false;
    }
  }

  void onPointerlockError() {
    console.warning('PointerLockControls: Unable to use Pointer Lock API');
  }

  void connect() {
    scope.domElement.addEventListener(PeripheralType.pointerHover, onMouseMove);
    scope.domElement.addEventListener(PeripheralType.pointerup, onMouseMove);
    scope.domElement.addEventListener(PeripheralType.pointerlockchange, onPointerlockChange);
    scope.domElement.addEventListener(PeripheralType.pointerlockerror, onPointerlockError);
  }

  void disconnect() {
    scope.domElement.removeEventListener(PeripheralType.pointerHover, onMouseMove);
    scope.domElement.removeEventListener(PeripheralType.pointerlockchange, onPointerlockChange);
    scope.domElement.removeEventListener(PeripheralType.pointerlockerror, onPointerlockError);
  }

  void dispose() {
    clearListeners();
  }

  Camera get getObject => camera;

  final direction = Vector3(0, 0, -1);

  Vector3 getDirection(Vector3 v) {
    return v.setFrom(direction).applyQuaternion(camera.quaternion);
  }

  void moveForward(distance) {
    // move forward parallel to the xz-plane
    // assumes camera.up is y-up
    _vector.setFromMatrixColumn(camera.matrix, 0);
    _vector.cross2(camera.up, _vector);
    camera.position.addScaled(_vector, distance);
  }

  void moveRight(distance) {
    _vector.setFromMatrixColumn(camera.matrix, 0);

    camera.position.addScaled(_vector, distance);
  }

  void lock() {
    isLocked = true;
    //domElement.requestPointerLock();
  }

  void unlock() {
    //scope.domElement.exitPointerLock();
  }
}
