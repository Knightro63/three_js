import 'dart:math' as math;
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'orbit_controls.dart';
import 'package:flutter/material.dart' hide Matrix4;

final _changeEvent = Event(type: 'change');
final _startEvent = Event(type: 'start');
final _endEvent = Event(type: 'end');

/// [TrackballControls] is similar to [OrbitControls]. However, it does not maintain a constant camera [up] vector.
/// That means if the camera orbits over the “north” and “south” poles, it does not flip to stay "right side up".
class TrackballControls with EventDispatcher {
  late TrackballControls scope;
  late Camera object;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;

  bool enabled = true;

  Map screen = {'left': 0, 'top': 0, 'width': 0, 'height': 0};

  double rotateSpeed = 1.0;
  double zoomSpeed = 1.2;
  double panSpeed = 0.3;

  bool noRotate = false;
  bool noZoom = false;
  bool noPan = false;

  bool staticMoving = false;
  double dynamicDampingFactor = 0.2;

  double minDistance = 0;
  double maxDistance = double.infinity;

  List<String> keys = ['KeyA' /*A*/, 'KeyS' /*S*/, 'KeyD' /*D*/];

  Map mouseButtons = {
    'LEFT': Mouse.rotate,
    'MIDDLE': Mouse.dolly,
    'RIGHT': Mouse.pan
  };

  // internals

  Vector3 target = Vector3();

  final eps = 0.000001;

  final lastPosition = Vector3();
  double lastZoom = 1.0;

  int _state = OrbitState.none,
      _keyState = OrbitState.none;
  double _touchZoomDistanceStart = 0.0,
      _touchZoomDistanceEnd = 0.0,
      _lastAngle = 0.0;

  final _eye = Vector3(),
    _movePrev = Vector2(),
    _moveCurr = Vector2(),
    _lastAxis = Vector3(),
    _zoomStart = Vector2(),
    _zoomEnd = Vector2(),
    _panStart = Vector2(),
    _panEnd = Vector2(),
    _pointers = [],
    _pointerPositions = {};

  late Vector3 target0;
  late Vector3 position0;
  late Vector3 up0;
  late double zoom0;

  /// [object] - The camera to be controlled.
  /// 
  /// [listenableKey] - The element used for event listeners.
  TrackballControls(this.object, this.listenableKey): super() {
    scope = this;

    target0 = target.clone();
    position0 = object.position.clone();
    up0 = object.up.clone();
    zoom0 = object.zoom;

    domElement.addEventListener(PeripheralType.contextmenu, contextmenu);
    domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.addEventListener(PeripheralType.pointercancel, onPointerCancel);
    domElement.addEventListener(PeripheralType.wheel, onMouseWheel);

    handleResize();
    update();
  }

  // methods

  void handleResize() {
    RenderBox getBox = listenableKey.currentContext?.findRenderObject() as RenderBox;
    var size = getBox.size;
    var local = getBox.globalToLocal(const Offset(0, 0));

    screen['left'] = local.dx;
    screen['top'] = local.dy;
    screen['width'] = size.width;
    screen['height'] = size.height;
  }

  final vector = Vector2();

  Vector2 getMouseOnScreen(num pageX, num pageY) {
    vector.setValues((pageX - scope.screen['left']) / scope.screen['width'],
        (pageY - scope.screen['top']) / scope.screen['height']);

    return vector;
  }

  Vector2 getMouseOnCircle(num pageX, num pageY) {
    vector.setValues(
        ((pageX - scope.screen['width'] * 0.5 - scope.screen['left']) /
            (scope.screen['width'] * 0.5)),
        ((scope.screen['height'] + 2 * (scope.screen['top'] - pageY)) /
            scope.screen['width']) // screen.width intentional
        );

    return vector;
  }

  final axis = Vector3(),
      quaternion = Quaternion(),
      eyeDirection = Vector3(),
      objectUpDirection = Vector3(),
      objectSidewaysDirection = Vector3(),
      moveDirection = Vector3();

  void rotateCamera() {
    moveDirection.setValues(_moveCurr.x - _movePrev.x, _moveCurr.y - _movePrev.y, 0);
    double angle = moveDirection.length;

    if (angle != 0) {
      _eye.setFrom(scope.object.position).sub(scope.target);

      eyeDirection.setFrom(_eye).normalize();
      objectUpDirection.setFrom(scope.object.up).normalize();
      objectSidewaysDirection
          .cross2(objectUpDirection, eyeDirection)
          .normalize();

      objectUpDirection.setLength(_moveCurr.y - _movePrev.y);
      objectSidewaysDirection.setLength(_moveCurr.x - _movePrev.x);

      moveDirection.setFrom(objectUpDirection.add(objectSidewaysDirection));

      axis.cross2(moveDirection, _eye).normalize();

      angle *= scope.rotateSpeed;
      quaternion.setFromAxisAngle(axis, angle);

      _eye.applyQuaternion(quaternion);
      scope.object.up.applyQuaternion(quaternion);

      _lastAxis.setFrom(axis);
      _lastAngle = angle;
    } else if (!scope.staticMoving && _lastAngle != 0) {
      _lastAngle *= math.sqrt(1.0 - scope.dynamicDampingFactor);
      _eye.setFrom(scope.object.position).sub(scope.target);
      quaternion.setFromAxisAngle(_lastAxis, _lastAngle);
      _eye.applyQuaternion(quaternion);
      scope.object.up.applyQuaternion(quaternion);
    }

    _movePrev.setFrom(_moveCurr);
  }

  void zoomCamera() {
    double factor;

    if (_state == OrbitState.touchZoomPan) {
      factor = _touchZoomDistanceStart / _touchZoomDistanceEnd;
      _touchZoomDistanceStart = _touchZoomDistanceEnd;

      if (scope.object is PerspectiveCamera) {
        _eye.scale(factor);
      } else if (scope.object is OrthographicCamera) {
        scope.object.zoom /= factor;
        scope.object.updateProjectionMatrix();
      } else {
        console.error('TrackballControls: Unsupported camera type');
      }
    } else {
      factor = 1.0 + (_zoomEnd.y - _zoomStart.y) * scope.zoomSpeed;

      if (factor != 1.0 && factor > 0.0) {
        if (scope.object is PerspectiveCamera) {
          _eye.scale(factor);
        } else if (scope.object is OrthographicCamera) {
          scope.object.zoom /= factor;
          scope.object.updateProjectionMatrix();
        } else {
          console.error('TrackballControls: Unsupported camera type');
        }
      }

      if (scope.staticMoving) {
        _zoomStart.setFrom(_zoomEnd);
      } else {
        _zoomStart.y += (_zoomEnd.y - _zoomStart.y) * dynamicDampingFactor;
      }
    }
  }

  final mouseChange = Vector2(),
      objectUp = Vector3(),
      pan = Vector3();

  void panCamera() {
    mouseChange.setFrom(_panEnd).sub(_panStart);

    if (mouseChange.length2 != 0) {
      if (scope.object is OrthographicCamera) {
        final scaleX = (scope.object.right - scope.object.left) /
            scope.object.zoom /
            scope.domElement.clientWidth;
        final scaleY = (scope.object.top - scope.object.bottom) /
            scope.object.zoom /
            scope.domElement.clientWidth;

        mouseChange.x *= scaleX;
        mouseChange.y *= scaleY;
      }

      mouseChange.scale(_eye.length * scope.panSpeed);

      pan.setFrom(_eye).cross(scope.object.up).setLength(mouseChange.x);
      pan.add(objectUp.setFrom(scope.object.up).setLength(mouseChange.y));

      scope.object.position.add(pan);
      scope.target.add(pan);

      if (scope.staticMoving) {
        _panStart.setFrom(_panEnd);
      } else {
        _panStart.add(mouseChange
            .sub2(_panEnd, _panStart)
            .scale(scope.dynamicDampingFactor));
      }
    }
  }

  void checkDistances() {
    if (!scope.noZoom || !scope.noPan) {
      if (_eye.length2 > scope.maxDistance * scope.maxDistance) {
        scope.object.position
            .add2(scope.target, _eye.setLength(scope.maxDistance));
        _zoomStart.setFrom(_zoomEnd);
      }

      if (_eye.length2 < scope.minDistance * scope.minDistance) {
        scope.object.position
            .add2(scope.target, _eye.setLength(scope.minDistance));
        _zoomStart.setFrom(_zoomEnd);
      }
    }
  }

  void update() {
    _eye.sub2(scope.object.position, scope.target);

    if (!scope.noRotate) {
      scope.rotateCamera();
    }

    if (!scope.noZoom) {
      scope.zoomCamera();
    }

    if (!scope.noPan) {
      scope.panCamera();
    }

    scope.object.position.add2(scope.target, _eye);

    if (scope.object is PerspectiveCamera) {
      scope.checkDistances();

      scope.object.lookAt(scope.target);

      if (lastPosition.distanceToSquared(scope.object.position) > eps) {
        scope.dispatchEvent(_changeEvent);

        lastPosition.setFrom(scope.object.position);
      }
    } else if (scope.object is OrthographicCamera) {
      scope.object.lookAt(scope.target);

      if (lastPosition.distanceToSquared(scope.object.position) > eps ||
          lastZoom != scope.object.zoom) {
        scope.dispatchEvent(_changeEvent);

        lastPosition.setFrom(scope.object.position);
        lastZoom = scope.object.zoom;
      }
    } else {
      console.error('THREE.TrackballControls: Unsupported camera type');
    }
  }

  void reset() {
    _state = OrbitState.none;
    _keyState = OrbitState.none;

    scope.target.setFrom(scope.target0);
    scope.object.position.setFrom(scope.position0);
    scope.object.up.setFrom(scope.up0);
    scope.object.zoom = scope.zoom0;

    scope.object.updateProjectionMatrix();

    _eye.sub2(scope.object.position, scope.target);

    scope.object.lookAt(scope.target);

    scope.dispatchEvent(_changeEvent);

    lastPosition.setFrom(scope.object.position);
    lastZoom = scope.object.zoom;
  }

  // listeners

  void onPointerDown(event) {
    if (scope.enabled == false) return;

    if (_pointers.isEmpty) {
      scope.domElement.setPointerCapture(event.pointerId);

      scope.domElement.addEventListener(PeripheralType.pointermove, onPointerMove);
      scope.domElement.addEventListener(PeripheralType.pointerup, onPointerUp);
    }

    //

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
    if (scope.enabled == false) return;

    if (event.pointerType == 'touch') {
      onTouchEnd(event);
    } else {
      onMouseUp();
    }

    //

    removePointer(event);

    if (_pointers.isEmpty) {
      scope.domElement.releasePointerCapture(event.pointerId);

      scope.domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
      scope.domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);
    }
  }

  void onPointerCancel(event) {
    removePointer(event);
  }

  void keydown(event) {
    if (scope.enabled == false) return;

    if (_keyState != OrbitState.none) {
      return;
    } else if (event.code == scope.keys[OrbitState.rotate] && !scope.noRotate) {
      _keyState = OrbitState.rotate;
    } else if (event.code == scope.keys[OrbitState.zoom] && !scope.noZoom) {
      _keyState = OrbitState.zoom;
    } else if (event.code == scope.keys[OrbitState.pan] && !scope.noPan) {
      _keyState = OrbitState.pan;
    }
  }

  void keyup() {
    if (scope.enabled == false) return;
    _keyState = OrbitState.none;
  }

  void onMouseDown(event) {
    if (_state == OrbitState.none) {
      if (event.button == scope.mouseButtons['LEFT']) {
        _state = OrbitState.rotate;
      } else if (event.button == scope.mouseButtons['MIDDLE']) {
        _state = OrbitState.zoom;
      } else if (event.button == scope.mouseButtons['RIGHT']) {
        _state = OrbitState.pan;
      }
    }

    final state = (_keyState != OrbitState.none) ? _keyState : _state;

    if (state == OrbitState.rotate && !scope.noRotate) {
      _moveCurr.setFrom(getMouseOnCircle(event.pageX, event.pageY));
      _movePrev.setFrom(_moveCurr);
    } else if (state == OrbitState.zoom && !scope.noZoom) {
      _zoomStart.setFrom(getMouseOnScreen(event.pageX, event.pageY));
      _zoomEnd.setFrom(_zoomStart);
    } else if (state == OrbitState.pan && !scope.noPan) {
      _panStart.setFrom(getMouseOnScreen(event.pageX, event.pageY));
      _panEnd.setFrom(_panStart);
    }

    scope.dispatchEvent(_startEvent);
  }

  void onMouseMove(event) {
    final state = (_keyState != OrbitState.none) ? _keyState : _state;

    if (state == OrbitState.rotate && !scope.noRotate) {
      _movePrev.setFrom(_moveCurr);
      _moveCurr.setFrom(getMouseOnCircle(event.pageX, event.pageY));
    } else if (state == OrbitState.zoom && !scope.noZoom) {
      _zoomEnd.setFrom(getMouseOnScreen(event.pageX, event.pageY));
    } else if (state == OrbitState.pan && !scope.noPan) {
      _panEnd.setFrom(getMouseOnScreen(event.pageX, event.pageY));
    }
  }

  void onMouseUp() {
    _state = OrbitState.none;
    scope.dispatchEvent(_endEvent);
  }

  void onMouseWheel(event) {
    if (scope.enabled == false) return;

    if (scope.noZoom == true) return;

    event.preventDefault();

    switch (event.deltaMode) {
      case 2:
        // Zoom in pages
        _zoomStart.y -= event.deltaY * 0.025;
        break;

      case 1:
        // Zoom in lines
        _zoomStart.y -= event.deltaY * 0.01;
        break;

      default:
        // undefined, 0, assume pixels
        _zoomStart.y -= event.deltaY * 0.00025;
        break;
    }

    scope.dispatchEvent(_startEvent);
    scope.dispatchEvent(_endEvent);
  }

  void onTouchStart(event) {
    trackPointer(event);

    switch (_pointers.length) {
      case 1:
        _state = OrbitState.touchRotate;
        _moveCurr.setFrom(getMouseOnCircle(_pointers[0].pageX, _pointers[0].pageY));
        _movePrev.setFrom(_moveCurr);
        break;

      default: // 2 or more
        _state = OrbitState.touchZoomPan;
        final dx = _pointers[0].pageX - _pointers[1].pageX;
        final dy = _pointers[0].pageY - _pointers[1].pageY;
        _touchZoomDistanceEnd = _touchZoomDistanceStart = math.sqrt(dx * dx + dy * dy);

        final x = (_pointers[0].pageX + _pointers[1].pageX) / 2;
        final y = (_pointers[0].pageY + _pointers[1].pageY) / 2;
        _panStart.setFrom(getMouseOnScreen(x, y));
        _panEnd.setFrom(_panStart);
        break;
    }

    scope.dispatchEvent(_startEvent);
  }

  void onTouchMove(event) {
    trackPointer(event);

    switch (_pointers.length) {
      case 1:
        _movePrev.setFrom(_moveCurr);
        _moveCurr.setFrom(getMouseOnCircle(event.pageX, event.pageY));
        break;

      default: // 2 or more

        final position = getSecondPointerPosition(event);

        final dx = event.pageX - position.x;
        final dy = event.pageY - position.y;
        _touchZoomDistanceEnd = math.sqrt(dx * dx + dy * dy);

        final x = (event.pageX + position.x) / 2;
        final y = (event.pageY + position.y) / 2;
        _panEnd.setFrom(getMouseOnScreen(x, y));
        break;
    }
  }

  void onTouchEnd(event) {
    switch (_pointers.length) {
      case 0:
        _state = OrbitState.none;
        break;

      case 1:
        _state = OrbitState.touchRotate;
        _moveCurr.setFrom(getMouseOnCircle(event.pageX, event.pageY));
        _movePrev.setFrom(_moveCurr);
        break;

      case 2:
        _state = OrbitState.touchZoomPan;
        _moveCurr.setFrom(getMouseOnCircle(event.pageX - _movePrev.x, event.pageY - _movePrev.y));
        _movePrev.setFrom(_moveCurr);
        break;
    }

    scope.dispatchEvent(_endEvent);
  }

  void contextmenu(event) {
    if (scope.enabled == false) return;
    event.preventDefault();
  }

  void addPointer(event) {
    _pointers.add(event);
  }

  void removePointer(event) {
    _pointerPositions.remove(event.pointerId);

    for (int i = 0; i < _pointers.length; i++) {
      if (_pointers[i].pointerId == event.pointerId && _pointers.length > 2) {
        _pointers.removeAt(1);
        return;
      }
    }
  }

  void trackPointer(event) {
    Vector2? position = _pointerPositions[event.pointerId];

    if (position == null) {
      position = Vector2();
      _pointerPositions[event.pointerId] = position;
    }

    position.setValues(event.pageX, event.pageY);
  }

  Vector2 getSecondPointerPosition(event) {
    final pointer = (event.pointerId == _pointers[0].pointerId)
        ? _pointers[1]
        : _pointers[0];

    return _pointerPositions[pointer.pointerId];
  }
  void dispose(){
    clearListeners();
  } 
  void disconnect() {
    scope.domElement.removeEventListener(PeripheralType.contextmenu, contextmenu);

    scope.domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    scope.domElement.removeEventListener(PeripheralType.pointercancel, onPointerCancel);
    scope.domElement.removeEventListener(PeripheralType.wheel, onMouseWheel);

    scope.domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
    scope.domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);
  }
}
