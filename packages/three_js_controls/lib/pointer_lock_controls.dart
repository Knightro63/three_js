part of three_js_controls;

class PointerLockControls with EventDispatcher {
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

  PointerLockControls(this.camera, this.listenableKey) : super() {
    scope = this;
    connect();
  }

  void onMouseMove(event) {
    print("onMouseMove event: $event isLocked ${scope.isLocked} ");
    if (scope.isLocked == false) return;

    final movementX = event.movementX ?? event.mozMovementX ?? event.webkitMovementX ?? 0;
    final movementY = event.movementY ?? event.mozMovementY ?? event.webkitMovementY ?? 0;

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
    print('THREE.PointerLockControls: Unable to use Pointer Lock API');
  }

  void connect() {
    scope.domElement.addEventListener(PeripheralType.mousemove, onMouseMove);
    scope.domElement.addEventListener(PeripheralType.pointerup, onMouseMove);
    scope.domElement.addEventListener(PeripheralType.pointerlockchange, onPointerlockChange);
    scope.domElement.addEventListener(PeripheralType.pointerlockerror, onPointerlockError);
  }

  void disconnect() {
    scope.domElement.removeEventListener(PeripheralType.mousemove, onMouseMove);
    scope.domElement.removeEventListener(PeripheralType.pointerlockchange, onPointerlockChange);
    scope.domElement.removeEventListener(PeripheralType.pointerlockerror, onPointerlockError);
  }

  void dispose() {
    disconnect();
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
    domElement.requestPointerLock();
  }

  void unlock() {
    scope.domElement.exitPointerLock();
  }
}
