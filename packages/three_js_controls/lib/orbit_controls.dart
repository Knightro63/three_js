import 'dart:math' as math;
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'spherical.dart';
import 'package:flutter/material.dart' hide Matrix4;

final _changeEvent = Event(type: 'change');
final _startEvent = Event(type: 'start');
final _endEvent = Event(type: 'end');

// This set of controls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - left mouse / touch: one-finger move
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - right mouse, or left mouse + ctrl/meta/shiftKey, or arrow Keys / touch: two-finger move

class OrbitState {
  static const int none = -1;
  static const int rotate = 0;
  static const int dolly = 1;
  static const int zoom = 1;
  static const int pan = 2;
  static const int touchRotate = 3;
  static const int touchPan = 4;
  static const int touchZoomPan = 4;
  static const int touchDollyPan = 5;
  static const int touchDollyRotate = 6;
}

// The four arrow Keys
class Keys {
  static const String left = 'ArrowLeft';
  static const String up = 'ArrowUp';
  static const String right = 'ArrowRight';
  static const String bottom = 'ArrowDown';
}

/// Orbit controls allow the camera to orbit around a target.
///
/// To use this, as with all files in the /examples directory, you will have to
/// include the file separately in your project.
class OrbitControls with EventDispatcher {
  late OrbitControls scope;
  late Camera object;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;

  // API
  late bool enabled;
  late Vector3 target;
  late Vector3 target0;
  late Vector3 position0;
  late double zoom0;

  late double minDistance;
  late double maxDistance;

  late double minZoom;
  late double maxZoom;

  late double minPolarAngle;
  late double maxPolarAngle;

  late double minAzimuthAngle;
  late double maxAzimuthAngle;

  late bool enableDamping;
  late double dampingFactor;

  late bool enableZoom;
  late double zoomSpeed;

  late bool enableRotate;
  late double rotateSpeed;

  late bool enablePan;
  late double panSpeed;
  late bool screenSpacePanning;
  late double keyPanSpeed;

  late bool autoRotate;
  late double autoRotateSpeed;

  late bool enableKeys;

  late Map<String, dynamic> mouseButtons;
  late Map<String, dynamic> touches;

  final changeEvent = Event(type: 'change');
  final startEvent = Event(type: 'start');
  final endEvent = Event(type: 'end');

  int state = OrbitState.none;
  double eps = 0.000001;

  // current position in spherical coordinates
  final spherical = Spherical();
  final sphericalDelta = Spherical();

  num scale = 1;
  final panOffset = Vector3();
  bool zoomChanged = false;

  final rotateStart = Vector2(0, 0);
  final rotateEnd = Vector2(null, null);
  final rotateDelta = Vector2(null, null);

  final panStart = Vector2(null, null);
  final panEnd = Vector2(null, null);
  final panDelta = Vector2(null, null);

  final dollyStart = Vector2(null, null);
  final dollyEnd = Vector2(null, null);
  final dollyDelta = Vector2(null, null);

  final infinity = double.infinity;

  List pointers = [];
  Map<int, Vector2> pointerPositions = {};

  final lastPosition = Vector3();
  final lastQuaternion = Quaternion();

  final twoPI = 2 * math.pi;

  late Quaternion quat;
  late Quaternion quatInverse;

  /// [object] - The camera to be controlled.
  /// 
  /// [listenableKey] - The element used for event listeners.
  OrbitControls(this.object, this.listenableKey):super() {
    scope = this;

    // Set to false to disable this control
    enabled = true;

    // "target" sets the location of focus, where the object orbits around
    target = Vector3();

    // How far you can dolly in and out ( PerspectiveCamera only )
    minDistance = 0;
    maxDistance = infinity;

    // How far you can zoom in and out ( OrthographicCamera only )
    minZoom = 0;
    maxZoom = infinity;

    // How far you can orbit vertically, upper and lower limits.
    // Range is 0 to math.pi radians.
    minPolarAngle = 0; // radians
    maxPolarAngle = math.pi; // radians

    // How far you can orbit horizontally, upper and lower limits.
    // If set, the interval [ min, max ] must be a sub-interval of [ - 2 PI, 2 PI ], with ( max - min < 2 PI )
    minAzimuthAngle = -infinity; // radians
    maxAzimuthAngle = infinity; // radians

    // Set to true to enable damping (inertia)
    // If damping is enabled, you must call controls.update() in your animation loop
    enableDamping = false;
    dampingFactor = 0.05;

    // This option actually enables dollying in and out; left as "zoom" for backwards compatibility.
    // Set to false to disable zooming
    enableZoom = true;
    zoomSpeed = 1.0;

    // Set to false to disable rotating
    enableRotate = true;
    rotateSpeed = 1.0;

    // Set to false to disable panning
    enablePan = true;
    panSpeed = 1.0;
    screenSpacePanning = true; // if false, pan orthogonal to world-space direction camera.up
    keyPanSpeed = 7.0; // pixels moved per arrow key push

    // Set to true to automatically rotate around the target
    // If auto-rotate is enabled, you must call controls.update() in your animation loop
    autoRotate = false;
    autoRotateSpeed = 2.0; // 30 seconds per orbit when fps is 60

    // Mouse buttons
    mouseButtons = {
      'left': Mouse.rotate,
      'MIDDLE': Mouse.dolly,
      'right': Mouse.pan
    };

    // Touch fingers
    touches = {'ONE': Touch.rotate, 'TWO': Touch.dollyPan};

    // for reset
    target0 = target.clone();
    position0 = object.position.clone();
    zoom0 = object.zoom;

    // the target DOM element for key events
    // this._domElementKeyEvents = null;

    scope.domElement.addEventListener(PeripheralType.contextmenu, onContextMenu);
    scope.domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    scope.domElement.addEventListener(PeripheralType.pointercancel, onPointerCancel);
    scope.domElement.addEventListener(PeripheralType.wheel, onMouseWheel);

    // force an update at start

    // so camera.up is the orbit axis
    quat = Quaternion().setFromUnitVectors(object.up, Vector3(0, 1, 0));
    quatInverse = quat.clone().invert();

    update();
  }

  num get getPolarAngle => spherical.phi;
  num get getAzimuthalAngle => spherical.theta;
  double get getDistance => object.position.distanceTo(target);

  void listenToKeyEvents(domElement) {
    domElement.addEventListener('keydown', onKeyDown);
  }

  void saveState() {
    scope.target0.setFrom(scope.target);
    scope.position0.setFrom(scope.object.position);
    scope.zoom0 = scope.object.zoom;
  }

  void reset() {
    scope.target.setFrom(scope.target0);
    scope.object.position.setFrom(scope.position0);
    scope.object.zoom = scope.zoom0;

    scope.object.updateProjectionMatrix();
    scope.dispatchEvent(_changeEvent);

    scope.update();

    state = OrbitState.none;
  }

  // this method is exposed, but perhaps it would be better if we can make it private...

  final offset = Vector3();

  bool update() {
    final position = scope.object.position;
    offset.setFrom(position).sub(scope.target);

    // rotate offset to "y-axis-is-up" space
    offset.applyQuaternion(quat);

    // angle from z-axis around y-axis
    spherical.setFromVector3(offset);

    if (scope.autoRotate && state == OrbitState.none) {
      rotateLeft(getAutoRotationAngle);
    }

    if (scope.enableDamping) {
      spherical.theta += sphericalDelta.theta * scope.dampingFactor;
      spherical.phi += sphericalDelta.phi * scope.dampingFactor;
    } 
    else {
      spherical.theta += sphericalDelta.theta;
      spherical.phi += sphericalDelta.phi;
    }

    // restrict theta to be between desired limits

    double min = scope.minAzimuthAngle;
    double max = scope.maxAzimuthAngle;

    if (min.isFinite && max.isFinite) {
      if (min < -math.pi){
        min += twoPI;
      }
      else if (min > math.pi){ 
        min -= twoPI;
      }

      if (max < -math.pi){
        max += twoPI;
      }
      else if (max > math.pi){ 
        max -= twoPI;
      }

      if (min <= max) {
        spherical.theta = math.max(min, math.min(max, spherical.theta));
      } 
      else {
        spherical.theta = (spherical.theta > (min + max) / 2)
            ? math.max(min, spherical.theta)
            : math.min(max, spherical.theta);
      }
    }

    // restrict phi to be between desired limits
    spherical.phi = math.max(
        scope.minPolarAngle, math.min(scope.maxPolarAngle, spherical.phi));

    spherical.makeSafe();

    spherical.radius *= scale;

    // restrict radius to be between desired limits
    spherical.radius = math.max(
        scope.minDistance, math.min(scope.maxDistance, spherical.radius));

    // move target to panned location

    if (scope.enableDamping == true) {
      scope.target.addScaled(panOffset, scope.dampingFactor);
    } 
    else {
      scope.target.add(panOffset);
    }

    offset.setFromSpherical(spherical);

    // rotate offset back to "camera-up-vector-is-up" space
    offset.applyQuaternion(quatInverse);
    position.setFrom(scope.target).add(offset);

    scope.object.lookAt(scope.target);

    if (scope.enableDamping == true) {
      sphericalDelta.theta *= (1 - scope.dampingFactor);
      sphericalDelta.phi *= (1 - scope.dampingFactor);

      panOffset.scale(1 - scope.dampingFactor);
    } 
    else {
      sphericalDelta.set(0, 0, 0);

      panOffset.setValues(0, 0, 0);
    }

    scale = 1;

    // update condition is:
    // min(camera displacement, camera rotation in radians)^2 > eps
    // using small-angle approximation cos(x/2) = 1 - x^2 / 8

    if (
      zoomChanged || 
      lastPosition.distanceToSquared(scope.object.position) > eps ||
      8 * (1 - lastQuaternion.dot(scope.object.quaternion)) > eps
    ) {
      scope.dispatchEvent(_changeEvent);

      lastPosition.setFrom(scope.object.position);
      lastQuaternion.setFrom(scope.object.quaternion);
      zoomChanged = false;

      return true;
    }

    return false;
  }

  void deactivate() {
    scope.domElement.removeEventListener(PeripheralType.contextmenu, onContextMenu);
    scope.domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    scope.domElement.removeEventListener(PeripheralType.pointercancel, onPointerCancel);
    scope.domElement.removeEventListener(PeripheralType.wheel, onMouseWheel);
    scope.domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
    scope.domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);
  }

  void dispose(){
    clearListeners();
  } 

  double get getAutoRotationAngle => 2 * math.pi / 60 / 60 * scope.autoRotateSpeed;

  num get getZoomScale => math.pow(0.95, scope.zoomSpeed);

  void rotateLeft(num angle) {
    sphericalDelta.theta -= angle;
  }

  void rotateUp(num angle) {
    sphericalDelta.phi -= angle;
  }

  final v = Vector3();

  void panLeft(num distance, Matrix4 objectMatrix) {
    v.setFromMatrixColumn(objectMatrix, 0); // get X column of objectMatrix
    v.scale(-distance);

    panOffset.add(v);
  }

  void panUp(num distance, Matrix4 objectMatrix) {
    if (scope.screenSpacePanning == true) {
      v.setFromMatrixColumn(objectMatrix, 1);
    } else {
      v.setFromMatrixColumn(objectMatrix, 0);
      v.cross2(scope.object.up, v);
    }

    v.scale(distance);

    panOffset.add(v);
  }

  // deltaX and deltaY are in pixels; right and down are positive
  void pan(double deltaX, double deltaY) {
    final element = scope.domElement;

    if (scope.object is PerspectiveCamera) {
      // perspective
      final position = scope.object.position;
      offset.setFrom(position).sub(scope.target);
      double targetDistance = offset.length;

      // half of the fov is center to top of screen
      targetDistance *= math.tan((scope.object.fov / 2) * math.pi / 180.0);

      // we use only clientHeight here so aspect ratio does not distort speed
      panLeft(2 * deltaX * targetDistance / element.clientHeight,
          scope.object.matrix);
      panUp(2 * deltaY * targetDistance / element.clientHeight,
          scope.object.matrix);
    } else if (scope.object is OrthographicCamera) {
      // orthographic
      panLeft(
          deltaX *
              (scope.object.right - scope.object.left) /
              scope.object.zoom /
              element.clientWidth,
          scope.object.matrix);
      panUp(
          deltaY *
              (scope.object.top - scope.object.bottom) /
              scope.object.zoom /
              element.clientHeight,
          scope.object.matrix);
    } else {
      // camera neither orthographic nor perspective
      console.warning('OrbitControls.js encountered an unknown camera type - pan disabled.');
      scope.enablePan = false;
    }
  }

  void dollyOut(num dollyScale) {
    if (scope.object is PerspectiveCamera) {
      scale /= dollyScale;
    } 
    else if (scope.object is OrthographicCamera) {
      scope.object.zoom = math.max(scope.minZoom,
          math.min(scope.maxZoom, scope.object.zoom * dollyScale));
      scope.object.updateProjectionMatrix();
      zoomChanged = true;
    } 
    else {
      console.warning('OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
      scope.enableZoom = false;
    }
  }

  void dollyIn(num dollyScale) {
    if (scope.object is PerspectiveCamera) {
      scale *= dollyScale;
    } 
    else if (scope.object is OrthographicCamera) {
      scope.object.zoom = math.max(scope.minZoom,
          math.min(scope.maxZoom, scope.object.zoom / dollyScale));
      scope.object.updateProjectionMatrix();
      zoomChanged = true;
    } 
    else {
      console.warning('OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
      scope.enableZoom = false;
    }
  }

  //
  // event callbacks - update the object state
  //

  void handleMouseDownRotate(event) {
    rotateStart.setValues(event.clientX, event.clientY);
  }

  void handleMouseDownDolly(event) {
    dollyStart.setValues(event.clientX, event.clientY);
  }

  void handleMouseDownPan(event) {
    panStart.setValues(event.clientX, event.clientY);
  }

  void handleMouseMoveRotate(event) {
    rotateEnd.setValues(event.clientX, event.clientY);

    rotateDelta.sub2(rotateEnd, rotateStart).scale(scope.rotateSpeed);

    final element = scope.domElement;

    rotateLeft(2 * math.pi * rotateDelta.x / element.clientHeight); // yes, height

    rotateUp(2 * math.pi * rotateDelta.y / element.clientHeight);

    rotateStart.setFrom(rotateEnd);

    scope.update();
  }

  void handleMouseMoveDolly(event) {
    dollyEnd.setValues(event.clientX, event.clientY);
    dollyDelta.sub2(dollyEnd, dollyStart);

    if (dollyDelta.y > 0) {
      dollyOut(getZoomScale);
    } else if (dollyDelta.y < 0) {
      dollyIn(getZoomScale);
    }

    dollyStart.setFrom(dollyEnd);
    scope.update();
  }

  void handleMouseMovePan(event) {
    panEnd.setValues(event.clientX, event.clientY);
    panDelta.sub2(panEnd, panStart).scale(scope.panSpeed);
    pan(panDelta.x, panDelta.y);
    panStart.setFrom(panEnd);
    scope.update();
  }

  void handleMouseWheel(event) {
    if (event.deltaY < 0) {
      dollyIn(getZoomScale);
    } else if (event.deltaY > 0) {
      dollyOut(getZoomScale);
    }

    scope.update();
  }

  void handleKeyDown(event) {
    bool needsUpdate = false;

    switch (event.code) {
      case Keys.up:
        pan(0, scope.keyPanSpeed);
        needsUpdate = true;
        break;

      case Keys.bottom:
        pan(0, -scope.keyPanSpeed);
        needsUpdate = true;
        break;

      case Keys.left:
        pan(scope.keyPanSpeed, 0);
        needsUpdate = true;
        break;

      case Keys.right:
        pan(-scope.keyPanSpeed, 0);
        needsUpdate = true;
        break;
    }

    if (needsUpdate) {
      // prevent the browser from scrolling on cursor Keys
      event.preventDefault();

      scope.update();
    }
  }

  void handleTouchStartRotate() {
    if (pointers.length == 1) {
      rotateStart.setValues(pointers[0].pageX, pointers[0].pageY);
    } else {
      final x = 0.5 * (pointers[0].pageX + pointers[1].pageX);
      final y = 0.5 * (pointers[0].pageY + pointers[1].pageY);

      rotateStart.setValues(x, y);
    }
  }

  void handleTouchStartPan() {
    if (pointers.length == 1) {
      panStart.setValues(pointers[0].pageX, pointers[0].pageY);
    } else {
      final x = 0.5 * (pointers[0].pageX + pointers[1].pageX);
      final y = 0.5 * (pointers[0].pageY + pointers[1].pageY);

      panStart.setValues(x, y);
    }
  }

  void handleTouchStartDolly() {
    final dx = pointers[0].pageX - pointers[1].pageX;
    final dy = pointers[0].pageY - pointers[1].pageY;

    final distance = math.sqrt(dx * dx + dy * dy);

    dollyStart.setValues(0, distance);
  }

  void handleTouchStartDollyPan() {
    if (scope.enableZoom) handleTouchStartDolly();

    if (scope.enablePan) handleTouchStartPan();
  }

  void handleTouchStartDollyRotate() {
    if (scope.enableZoom) handleTouchStartDolly();

    if (scope.enableRotate) handleTouchStartRotate();
  }

  void handleTouchMoveRotate(event) {
    if (pointers.length == 1) {
      rotateEnd.setValues(event.pageX, event.pageY);
    } else {
      final position = getSecondPointerPosition(event)!;

      final x = 0.5 * (event.pageX + position.x);
      final y = 0.5 * (event.pageY + position.y);

      rotateEnd.setValues(x, y);
    }

    rotateDelta.sub2(rotateEnd, rotateStart).scale(scope.rotateSpeed);

    final element = scope.domElement;

    rotateLeft(2 * math.pi * rotateDelta.x / element.clientHeight); // yes, height
    rotateUp(2 * math.pi * rotateDelta.y / element.clientHeight);
    rotateStart.setFrom(rotateEnd);
  }

  void handleTouchMovePan(event) {
    if (pointers.length == 1) {
      panEnd.setValues(event.pageX, event.pageY);
    } else {
      final position = getSecondPointerPosition(event)!;

      final x = 0.5 * (event.pageX + position.x);
      final y = 0.5 * (event.pageY + position.y);

      panEnd.setValues(x, y);
    }

    panDelta.sub2(panEnd, panStart).scale(scope.panSpeed);

    pan(panDelta.x, panDelta.y);

    panStart.setFrom(panEnd);
  }

  void handleTouchMoveDolly(event) {
    final position = getSecondPointerPosition(event)!;

    console.info("handleTouchMoveDolly event.pageX: ${event.pageX} position.x: ${position.x} ");

    final dx = event.pageX - position.x;
    final dy = event.pageY - position.y;

    final distance = math.sqrt(dx * dx + dy * dy);

    dollyEnd.setValues(0, distance);

    dollyDelta.setValues(0, math.pow(dollyEnd.y / dollyStart.y, scope.zoomSpeed).toDouble());

    dollyOut(dollyDelta.y);

    dollyStart.setFrom(dollyEnd);
  }

  void handleTouchMoveDollyPan(event) {
    if (scope.enableZoom) handleTouchMoveDolly(event);

    if (scope.enablePan) handleTouchMovePan(event);
  }

  void handleTouchMoveDollyRotate(event) {
    if (scope.enableZoom) handleTouchMoveDolly(event);

    if (scope.enableRotate) handleTouchMoveRotate(event);
  }

  //
  // event handlers - FSM: listen for events and reset state
  //

  void onPointerDown(event) {
    if (scope.enabled == false) return;

    if (pointers.isEmpty) {
      scope.domElement.setPointerCapture(event.pointerId);

      scope.domElement.addEventListener(PeripheralType.pointermove, onPointerMove);
      scope.domElement.addEventListener(PeripheralType.pointerup, onPointerUp);
    }

    addPointer(event);

    if (event.pointerType == 'touch') {
      onTouchStart(event);
    } else {
      onMouseDown(event);
    }
  }

  void onPointerMove(event) {
    if (scope.enabled == false) return;

    if (event.pointerType == 'touch') {
      onTouchMove(event);
    } else {
      onMouseMove(event);
    }
  }

  void onPointerUp(event) {
    removePointer(event);

    if (pointers.isEmpty) {
      scope.domElement.releasePointerCapture(event.pointerId);

      scope.domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
      scope.domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);
    }

    scope.dispatchEvent(_endEvent);

    state = OrbitState.none;
  }

  void onPointerCancel(event) {
    removePointer(event);
  }

  void onMouseDown(event) {
    dynamic mouseAction;

    switch (event.button) {
      case 0:
        mouseAction = scope.mouseButtons['left'];
        break;

      case 1:
        mouseAction = scope.mouseButtons['MIDDLE'];
        break;

      case 2:
        mouseAction = scope.mouseButtons['right'];
        break;

      default:
        mouseAction = -1;
    }

    switch (mouseAction) {
      case Mouse.dolly:
        if (scope.enableZoom == false) return;

        handleMouseDownDolly(event);

        state = OrbitState.dolly;

        break;

      case Mouse.rotate:
        if (event.ctrlKey || event.metaKey || event.shiftKey) {
          if (scope.enablePan == false) return;

          handleMouseDownPan(event);

          state = OrbitState.pan;
        } else {
          if (scope.enableRotate == false) return;

          handleMouseDownRotate(event);

          state = OrbitState.rotate;
        }

        break;

      case Mouse.pan:
        if (event.ctrlKey || event.metaKey || event.shiftKey) {
          if (scope.enableRotate == false) return;

          handleMouseDownRotate(event);

          state = OrbitState.rotate;
        } else {
          if (scope.enablePan == false) return;

          handleMouseDownPan(event);

          state = OrbitState.pan;
        }

        break;

      default:
        state = OrbitState.none;
    }

    if (state != OrbitState.none) {
      scope.dispatchEvent(_startEvent);
    }
  }

  void onMouseMove(event) {
    if (scope.enabled == false) return;

    switch (state) {
      case OrbitState.rotate:
        if (scope.enableRotate == false) return;

        handleMouseMoveRotate(event);

        break;

      case OrbitState.dolly:
        if (scope.enableZoom == false) return;

        handleMouseMoveDolly(event);

        break;

      case OrbitState.pan:
        if (scope.enablePan == false) return;

        handleMouseMovePan(event);

        break;
    }
  }

  void onMouseWheel(event) {
    if (scope.enabled == false ||
        scope.enableZoom == false ||
        state != OrbitState.none) return;

    event.preventDefault();

    scope.dispatchEvent(_startEvent);

    handleMouseWheel(event);

    scope.dispatchEvent(_endEvent);
  }

  void onKeyDown(event) {
    if (scope.enabled == false || scope.enablePan == false) return;

    handleKeyDown(event);
  }

  void onTouchStart(event) {
    trackPointer(event);

    switch (pointers.length) {
      case 1:
        switch (scope.touches['ONE']) {
          case Touch.rotate:
            if (scope.enableRotate == false) return;

            handleTouchStartRotate();

            state = OrbitState.touchRotate;

            break;

          case Touch.pan:
            if (scope.enablePan == false) return;

            handleTouchStartPan();

            state = OrbitState.touchPan;

            break;

          default:
            state = OrbitState.none;
        }

        break;

      case 2:
        switch (scope.touches['TWO']) {
          case Touch.dollyPan:
            if (scope.enableZoom == false && scope.enablePan == false) return;
            handleTouchStartDollyPan();
            state = OrbitState.touchDollyPan;
            break;
          case Touch.dollyRotate:
            if (scope.enableZoom == false && scope.enableRotate == false){
              return;
            }
            handleTouchStartDollyRotate();
            state = OrbitState.touchDollyRotate;
            break;
          default:
            state = OrbitState.none;
        }

        break;

      default:
        state = OrbitState.none;
    }

    if (state != OrbitState.none) {
      scope.dispatchEvent(_startEvent);
    }
  }

  void onTouchMove(event) {
    trackPointer(event);

    switch (state) {
      case OrbitState.touchRotate:
        if (scope.enableRotate == false) return;

        handleTouchMoveRotate(event);

        scope.update();

        break;

      case OrbitState.touchPan:
        if (scope.enablePan == false) return;

        handleTouchMovePan(event);

        scope.update();

        break;

      case OrbitState.touchDollyPan:
        if (scope.enableZoom == false && scope.enablePan == false) return;

        handleTouchMoveDollyPan(event);

        scope.update();

        break;

      case OrbitState.touchDollyRotate:
        if (scope.enableZoom == false && scope.enableRotate == false) return;

        handleTouchMoveDollyRotate(event);

        scope.update();

        break;

      default:
        state = OrbitState.none;
    }
  }

  void onContextMenu(event) {
    if (scope.enabled == false) return;

    event.preventDefault();
  }

  void addPointer(event) {
    pointers.add(event);
  }

  void removePointer(event) {
    pointerPositions.remove(event.pointerId);

    for (int i = 0; i < pointers.length; i++) {
      if (pointers[i].pointerId == event.pointerId) {
        pointers.removeAt(i);
        return;
      }
    }
  }

  void trackPointer(event) {
    Vector2? position = pointerPositions[event.pointerId];

    if (position == null) {
      position = Vector2();
      pointerPositions[event.pointerId] = position;
    }

    position.setValues(event.pageX, event.pageY);
  }

  Vector2? getSecondPointerPosition(event) {
    final pointer =
        (event.pointerId == pointers[0].pointerId) ? pointers[1] : pointers[0];

    return pointerPositions[pointer.pointerId];
  }
}

// This set of controls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
// This is very similar to OrbitControls, another set of touch behavior
//
//    Orbit - right mouse, or left mouse + ctrl/meta/shiftKey / touch: two-finger rotate
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - left mouse, or arrow Keys / touch: one-finger move

class MapControls extends OrbitControls {
  MapControls(super.object, super.domElement){
    screenSpacePanning = false; // pan orthogonal to world-space direction camera.up

    mouseButtons['left'] = Mouse.pan;
    mouseButtons['right'] = Mouse.rotate;

    touches['ONE'] = Touch.pan;
    touches['TWO'] = Touch.dollyRotate;
  }
}
