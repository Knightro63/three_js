part of three_js_transform_controls;

//trackball state
class State2 {
  static const int idle = 0;
  static const int rotate = 1;
  static const int pan = 2;
  static const int scale = 3;
  static const int fov = 4;
  static const int focus = 5;
  static const int zRotate = 6;
  static const int touchMulti = 7;
  static const int animationFocus = 8;
  static const int animationRotate = 9;
}

class Input {
  static const int none = 0;
  static const int oneFinger = 1;
  static const int oneFingerSwitched = 2;
  static const int twoFinger = 3;
  static const int multiFinger = 4;
  static const int cursor = 5;
}

//cursor center coordinates
Vector2 _center = Vector2(0, 0);

//transformation matrices for gizmos and camera
Map<String,Matrix4> _transformation = {'camera': Matrix4(), 'gizmos': Matrix4()};

Matrix4 _gizmoMatrixStateTemp = Matrix4();
Matrix4 _cameraMatrixStateTemp = Matrix4();
Vector3 _scalePointTemp = Vector3();

/// Arcball controls allow the camera to be controlled by a virtual trackball with full touch support and advanced navigation functionality.
/// 
/// Cursor/finger positions and movements are mapped over a virtual trackball surface
/// represented by a gizmo and mapped in intuitive and consistent camera movements.
/// Dragging cursor/fingers will cause camera to orbit around the center of the trackball in a conservative way (returning to the starting point
/// will make the camera to return to its starting orientation).
///
///
/// In addition to supporting pan, zoom and pinch gestures, Arcball controls provide <i>focus</i> functionality with a double click/tap for
/// intuitively moving the object's point of interest in the center of the virtual trackball.
/// Focus allows a much better inspection and navigation in complex environment.
/// Moreover Arcball controls allow FOV manipulation (in a vertigo-style method) and z-rotation.
/// Saving and restoring of Camera State is supported also through clipboard
/// (use ctrl+c and ctrl+v shortcuts for copy and paste the state).
///
///
/// Unlike [OrbitControls] and [TrackballControls], [ArcballControls] doesn't require [update] to be called externally in an animation loop when animations
/// are on.
///
///
/// To use this, as with all files in the /examples directory, you will have to
/// include the file separately in your HTML.
class ArcballControls with EventDispatcher {
  bool disposed = false;
  Vector3 target = Vector3();
  final Vector3 _currentTarget = Vector3();
  double radiusFactor = 0.67;

  final mouseActions = [];
  String? _mouseOp;

  //global vectors and matrices that are used in some operations to avoid creating objects every time (e.g. every time cursor moves)
  final Vector2 _v2_1 = Vector2();
  final Vector3 _v3_1 = Vector3();
  final Vector3 _v3_2 = Vector3();

  final Matrix4 _m4_1 = Matrix4();
  final Matrix4 _m4_2 = Matrix4();

  final Quaternion _quat = Quaternion();

  //transformation matrices
  final Matrix4 _translationMatrix = Matrix4(); //matrix for translation operation
  final Matrix4 _rotationMatrix = Matrix4(); //matrix for rotation operation
  final Matrix4 _scaleMatrix = Matrix4(); //matrix for scaling operation

  final Vector3 _rotationAxis = Vector3(); //axis for rotate operation

  //camera state
  final Matrix4 _cameraMatrixState = Matrix4();
  final Matrix4 _cameraProjectionState = Matrix4();

  double _fovState = 1;
  final Vector3 _upState = Vector3();
  double _zoomState = 1;
  double _nearPos = 0;
  double _farPos = 0;

  final Matrix4 _gizmoMatrixState = Matrix4();

  //initial values
  final Vector3 _up0 = Vector3();
  double _zoom0 = 1;
  double _fov0 = 0;
  double _initialNear = 0;
  double _nearPos0 = 0;
  double _initialFar = 0;
  double _farPos0 = 0;
  final Matrix4 _cameraMatrixState0 = Matrix4();
  final Matrix4 _gizmoMatrixState0 = Matrix4();

  //pointers array
  int _button = -1;
  final _touchStart = [];
  final _touchCurrent = [];
  int _input = Input.none;

  //two fingers touch interaction
  final int _switchSensibility = 32; //minimum movement to be performed to fire single pan start after the second finger has been released
  double _startFingerDistance = 0; //distance between two fingers
  double _currentFingerDistance = 0;
  double _startFingerRotation = 0; //amount of rotation performed with two fingers
  double _currentFingerRotation = 0;

  //double tap
  double _devPxRatio = 0;
  bool _downValid = true;
  int _nclicks = 0;
  final _downEvents = [];
  //int _downStart = 0; //pointerDown time
  int _clickStart = 0; //first click time
  final int _maxDownTime = 250;
  final int _maxInterval = 300;
  final int _posThreshold = 24;
  final int _movementThreshold = 24;

  //cursor positions
  final _currentCursorPosition = Vector3();
  final _startCursorPosition = Vector3();

  //grid
  GridHelper? _grid; //grid to be visualized during pan operation
  final _gridPosition = Vector3();

  //gizmos
  final _gizmos = Group();
  final int _curvePts = 128;

  //animations
  int _timeStart = -1; //initial time
  int _animationId = -1;

  //focus animation
  final focusAnimationTime = 500; //duration of focus animation in ms

  //rotate animation
  int _timePrev = 0; //time at which previous rotate operation has been detected
  int _timeCurrent = 0; //time at which current rotate operation has been detected
  double _anglePrev = 0; //angle of previous rotation
  double _angleCurrent = 0; //angle of current rotation
  final _cursorPosPrev = Vector3(); //cursor position when previous rotate operation has been detected
  final _cursorPosCurr = Vector3(); //cursor position when current rotate operation has been detected
  double _wPrev = 0; //angular velocity of the previous rotate operation
  double _wCurr = 0; //angular velocity of the current rotate operation

  //parameters
  bool adjustNearFar = false;
  double scaleFactor = 1.1; //zoom/distance multiplier
  int dampingFactor = 25;
  int wMax = 20; //maximum angular velocity allowed
  bool enableAnimations = true; //if animations should be performed
  bool enableGrid = false; //if grid should be showed during pan operation
  bool cursorZoom = false; //if wheel zoom should be cursor centered
  double minFov = 5;
  double maxFov = 90;

  bool enabled = true;
  bool enablePan = true;
  bool enableRotate = true;
  bool enableZoom = true;
  bool enableGizmos = true;

  double minDistance = 0;
  double maxDistance = double.infinity;
  double minZoom = 0;
  double maxZoom = double.infinity;

  //trackball parameters
  double _tbRadius = 1;

  //late OrbitControls scope;
  late Camera camera;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;

  Scene? scene;
  dynamic _state;

  /// [camera] - (required) The camera to be controlled. The camera must not be a child of another object, unless that object is the scene itself.
  /// 
  /// [listenableKey] - The element used for event listeners.
  /// 
  /// [scene] - The scene rendered by the camera. If not given, gizmos cannot be shown.
  ArcballControls(this.camera, this.listenableKey, [this.scene, double devicePixelRatio = 1.0]): super() {
    //FSA
    _state = State2.idle;

    setCamera(camera);

    if (scene != null) {
      scene!.add(_gizmos);
    }

    // domElement.style.touchAction = 'none';
    _devPxRatio = devicePixelRatio;

    initializeMouseActions();

    domElement.addEventListener(PeripheralType.contextmenu, onContextMenu);
    domElement.addEventListener(PeripheralType.wheel, onWheel);
    domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.addEventListener(PeripheralType.pointercancel, onPointerCancel);

    // window.addEventListener( PeripheralType.resize, onWindowResize );
  }

  //listeners

  void onWindowResize() {
    final scale = (_gizmos.scale.x + _gizmos.scale.y + _gizmos.scale.z) /3;
    _tbRadius = calculateTbRadius(camera);

    final newRadius = _tbRadius / scale;
    final curve = EllipseCurve(0, 0, newRadius, newRadius);
    final points = curve.getPoints(_curvePts);
    final curveGeometry = BufferGeometry().setFromPoints(points);

    for (Object3D gizmo in _gizmos.children) {
      // _gizmos.children[ gizmo ].geometry = curveGeometry;
      gizmo.geometry = curveGeometry;
    }

    dispatchEvent(_changeEvent);
  }

  void onContextMenu(event) {
    if (!enabled) {
      return;
    }

    for (int i = 0; i < mouseActions.length; i++) {
      if (mouseActions[i]['mouse'] == 2) {
        //prevent only if button 2 is actually used
        event.preventDefault();
        break;
      }
    }
  }

  void onPointerCancel() {
    _touchStart.clear();
    _touchCurrent.clear();
    _input = Input.none;
  }

  void onPointerDown(event) {
    if (event.button == 0 && event.isPrimary) {
      _downValid = true;
      _downEvents.add(event);
      //_downStart = DateTime.now().millisecondsSinceEpoch;
    } 
    else {
      _downValid = false;
    }

    if (event.pointerType == 'touch' && _input != Input.cursor) {
      _touchStart.add(event);
      _touchCurrent.add(event);

      switch (_input) {
        case Input.none:

          //singleStart
          _input = Input.oneFinger;
          onSinglePanStart(event, 'rotate');

          domElement.addEventListener(PeripheralType.pointermove, onPointerMove);
          domElement.addEventListener(PeripheralType.pointerup, onPointerUp);

          break;

        case Input.oneFinger:
        case Input.oneFingerSwitched:

          //doubleStart
          _input = Input.twoFinger;

          onRotateStart();
          onPinchStart();
          onDoublePanStart();

          break;

        case Input.twoFinger:

          //multipleStart
          _input = Input.multiFinger;
          onTriplePanStart(event);
          break;
      }
    } 
    else if (event.pointerType != 'touch' && _input == Input.none) {
      String? modifier;

      if (event.ctrlKey || event.metaKey) {
        modifier = 'CTRL';
      } 
      else if (event.shiftKey) {
        modifier = 'SHIFT';
      }

      _mouseOp = getOpFromAction(event.button, modifier);

      if (_mouseOp != null) {
        domElement.addEventListener(PeripheralType.pointermove, onPointerMove);
        domElement.addEventListener(PeripheralType.pointerup, onPointerUp);

        //singleStart
        _input = Input.cursor;
        _button = event.button;
        onSinglePanStart(event, _mouseOp);
      }
    }
  }

  void onPointerMove(event) {
    if (event.pointerType == 'touch' && _input != Input.cursor) {
      switch (_input) {
        case Input.oneFinger:

          //singleMove
          updateTouchEvent(event);

          onSinglePanMove(event, State2.rotate);
          break;

        case Input.oneFingerSwitched:
          final movement =
              calculatePointersDistance(_touchCurrent[0], event) *
                  _devPxRatio;

          if (movement >= _switchSensibility) {
            //singleMove
            _input = Input.oneFinger;
            updateTouchEvent(event);

            onSinglePanStart(event, 'rotate');
            break;
          }

          break;

        case Input.twoFinger:

          //rotate/pan/pinchMove
          updateTouchEvent(event);

          onRotateMove();
          onPinchMove();
          onDoublePanMove();

          break;

        case Input.multiFinger:

          //multMove
          updateTouchEvent(event);

          onTriplePanMove(event);
          break;
      }
    } 
    else if (event.pointerType != 'touch' && _input == Input.cursor) {
      String? modifier;

      if (event.ctrlKey || event.metaKey) {
        modifier = 'CTRL';
      } else if (event.shiftKey) {
        modifier = 'SHIFT';
      }

      final mouseOpState = getOpStateFromAction(_button, modifier);

      if (mouseOpState != null) {
        onSinglePanMove(event, mouseOpState);
      }
    }

    //checkDistance
    if (_downValid) {
      final movement = calculatePointersDistance(
              _downEvents[_downEvents.length - 1], event) *
          _devPxRatio;
      if (movement > _movementThreshold) {
        _downValid = false;
      }
    }
  }

  void onPointerUp(event) {
    if (event.pointerType == 'touch' && _input != Input.cursor) {
      final nTouch = _touchCurrent.length;

      for (int i = 0; i < nTouch; i++) {
        if (_touchCurrent[i].pointerId == event.pointerId) {
          _touchCurrent.removeAt(i);
          _touchStart.removeAt(i);
          break;
        }
      }

      switch (_input) {
        case Input.oneFinger:
        case Input.oneFingerSwitched:

          //singleEnd
          domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
          domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);

          _input = Input.none;
          onSinglePanEnd();

          break;

        case Input.twoFinger:

          //doubleEnd
          onDoublePanEnd(event);
          onPinchEnd(event);
          onRotateEnd(event);

          //switching to singleStart
          _input = Input.oneFingerSwitched;

          break;

        case Input.multiFinger:
          if (_touchCurrent.isEmpty) {
            domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
            domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);

            //multCancel
            _input = Input.none;
            onTriplePanEnd();
          }

          break;
      }
    } else if (event.pointerType != 'touch' && _input == Input.cursor) {
      domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
      domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);

      _input = Input.none;
      onSinglePanEnd();
      _button = -1;
    }

    if (event.isPrimary) {
      if (_downValid) {
        final downTime = event.timeStamp -
            _downEvents[_downEvents.length - 1].timeStamp;

        if (downTime <= _maxDownTime) {
          if (_nclicks == 0) {
            //first valid click detected
            _nclicks = 1;
            _clickStart = DateTime.now().millisecondsSinceEpoch;
          } else {
            final clickInterval = event.timeStamp - _clickStart;
            final movement = calculatePointersDistance(
                    _downEvents[1], _downEvents[0]) *
                _devPxRatio;

            if (clickInterval <= _maxInterval &&
                movement <= _posThreshold) {
              //second valid click detected
              //fire double tap and reset values
              _nclicks = 0;
              _downEvents.clear();
              onDoubleTap(event);
            } else {
              //'first click'
              _nclicks = 1;
              _downEvents.removeAt(0);
              _clickStart = DateTime.now().millisecondsSinceEpoch;
            }
          }
        } else {
          _downValid = false;
          _nclicks = 0;
          _downEvents.clear();
        }
      } else {
        _nclicks = 0;
        _downEvents.clear();
      }
    }
  }

  void onWheel(event) {
    if (enabled && enableZoom) {
      String? modifier;

      if (event.ctrlKey || event.metaKey) {
        modifier = 'CTRL';
      } else if (event.shiftKey) {
        modifier = 'SHIFT';
      }

      final mouseOp = getOpFromAction(3, modifier);

      if (mouseOp != null) {
        event.preventDefault();
        dispatchEvent(_startEvent);

        const notchDeltaY = 125; //distance of one notch of mouse wheel
        double sgn = event.deltaY / notchDeltaY;

        double size = 1;

        if (sgn > 0) {
          size = 1 / scaleFactor;
        } else if (sgn < 0) {
          size = scaleFactor;
        }

        switch (mouseOp) {
          case 'ZOOM':
            updateTbState(State2.scale, true);

            if (sgn > 0) {
              size = 1 / (math.pow(scaleFactor, sgn));
            } else if (sgn < 0) {
              size = math.pow(scaleFactor, -sgn) + 0.0;
            }

            if (cursorZoom && enablePan) {
              Vector3? scalePoint;

              if (camera is OrthographicCamera) {
                scalePoint = unprojectOnTbPlane(camera, event.clientX,event.clientY)
                    .applyQuaternion(camera.quaternion)
                    .scale(1 / camera.zoom)
                    .add(_gizmos.position);
              } 
              else if (camera is PerspectiveCamera) {
                scalePoint = unprojectOnTbPlane(camera, event.clientX, event.clientY)
                    .applyQuaternion(camera.quaternion)
                    .add(_gizmos.position);
              }

              applyTransformMatrix(scale(size, scalePoint));
            } 
            else {
              applyTransformMatrix(
                  scale(size, _gizmos.position));
            }

            if (_grid != null) {
              disposeGrid();
              drawGrid();
            }

            updateTbState(State2.idle, false);

            dispatchEvent(_changeEvent);
            dispatchEvent(_endEvent);

            break;

          case 'fov':
            if (camera is PerspectiveCamera) {
              updateTbState(State2.fov, true);

              //Vertigo effect

              //	  fov / 2
              //		|\
              //		| \
              //		|  \
              //	x	|	\
              //		| 	 \
              //		| 	  \
              //		| _ _ _\
              //			y

              //check for iOs shift shortcut
              if (event.deltaX != 0) {
                sgn = event.deltaX / notchDeltaY;

                size = 1;

                if (sgn > 0) {
                  size = 1 / (math.pow(scaleFactor, sgn));
                } else if (sgn < 0) {
                  size = math.pow(scaleFactor, -sgn) + 0.0;
                }
              }

              _v3_1.setFromMatrixPosition(_cameraMatrixState);
              final x = _v3_1.distanceTo(_gizmos.position);
              double xNew = x /size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

              //check min and max distance
              xNew = MathUtils.clamp(xNew, minDistance, maxDistance);

              final y = x * math.tan(MathUtils.deg2rad * camera.fov * 0.5);

              //calculate fov
              double newFov = MathUtils.rad2deg * (math.atan(y / xNew) * 2);

              //check min and max fov
              if (newFov > maxFov) {
                newFov = maxFov;
              } 
              else if (newFov < minFov) {
                newFov = minFov;
              }

              final newDistance = y / math.tan(MathUtils.deg2rad * (newFov / 2));
              size = x / newDistance;

              setFov(newFov);
              applyTransformMatrix(
                  scale(size, _gizmos.position, false));
            }

            if (_grid != null) {
              disposeGrid();
              drawGrid();
            }

            updateTbState(State2.idle, false);

            dispatchEvent(_changeEvent);
            dispatchEvent(_endEvent);

            break;
        }
      }
    }
  }

  void onSinglePanStart(event, operation) {
    if (enabled) {
      dispatchEvent(_startEvent);

      setCenter(event.clientX, event.clientY);

      switch (operation) {
        case 'pan':
          if (!enablePan) {
            return;
          }

          if (_animationId != -1) {
            cancelAnimationFrame(_animationId);
            _animationId = -1;
            _timeStart = -1;

            activateGizmos(false);
            dispatchEvent(_changeEvent);
          }

          updateTbState(State2.pan, true);
          _startCursorPosition.setFrom(unprojectOnTbPlane(camera, _center.x, _center.y));
          if (enableGrid) {
            drawGrid();
            dispatchEvent(_changeEvent);
          }

          break;

        case 'rotate':
          if (!enableRotate) {
            return;
          }

          if (_animationId != -1) {
            cancelAnimationFrame(_animationId);
            _animationId = -1;
            _timeStart = -1;
          }

          updateTbState(State2.rotate, true);
          _startCursorPosition.setFrom(unprojectOnTbSurface(camera,
              _center.x, _center.y,_tbRadius));
          activateGizmos(true);
          if (enableAnimations) {
            _timePrev = _timeCurrent = DateTime.now().millisecondsSinceEpoch;
            _angleCurrent = _anglePrev = 0;
            _cursorPosPrev.setFrom(_startCursorPosition);
            _cursorPosCurr.setFrom(_cursorPosPrev);
            _wCurr = 0;
            _wPrev = _wCurr;
          }

          dispatchEvent(_changeEvent);
          break;

        case 'fov':
          if (camera is! PerspectiveCamera || !enableZoom) {
            return;
          }

          if (_animationId != -1) {
            cancelAnimationFrame(_animationId);
            _animationId = -1;
            _timeStart = -1;

            activateGizmos(false);
            dispatchEvent(_changeEvent);
          }

          updateTbState(State2.fov, true);
          _startCursorPosition.setY(
              getCursorNDC(_center.x, _center.y).y * 0.5);
          _currentCursorPosition.setFrom(_startCursorPosition);
          break;

        case 'ZOOM':
          if (!enableZoom) {
            return;
          }

          if (_animationId != -1) {
            cancelAnimationFrame(_animationId);
            _animationId = -1;
            _timeStart = -1;

            activateGizmos(false);
            dispatchEvent(_changeEvent);
          }

          updateTbState(State2.scale, true);
          _startCursorPosition.setY(
              getCursorNDC(_center.x, _center.y).y * 0.5);
          _currentCursorPosition.setFrom(_startCursorPosition);
          break;
      }
    }
  }

  void onSinglePanMove(event, opState) {
    if (enabled) {
      final restart = opState != _state;
      setCenter(event.clientX, event.clientY);

      switch (opState) {
        case State2.pan:
          if (enablePan) {
            if (restart) {
              //switch to pan operation

              dispatchEvent(_endEvent);
              dispatchEvent(_startEvent);

              updateTbState(opState, true);
              _startCursorPosition.setFrom(unprojectOnTbPlane(camera, _center.x, _center.y));
              if (enableGrid) {
                drawGrid();
              }

              activateGizmos(false);
            } else {
              //continue with pan operation
              _currentCursorPosition.setFrom(unprojectOnTbPlane(camera, _center.x, _center.y));
              applyTransformMatrix(pan(_startCursorPosition, _currentCursorPosition));
            }
          }

          break;

        case State2.rotate:
          if (enableRotate) {
            if (restart) {
              //switch to rotate operation

              dispatchEvent(_endEvent);
              dispatchEvent(_startEvent);

              updateTbState(opState, true);
              _startCursorPosition.setFrom(
                unprojectOnTbSurface(
                  camera,
                  _center.x,
                  _center.y,
                  _tbRadius
                )
              );

              if (enableGrid) {
                disposeGrid();
              }

              activateGizmos(true);
            } else {
              //continue with rotate operation
              _currentCursorPosition.setFrom(
                unprojectOnTbSurface(
                  camera,
                  _center.x,
                  _center.y,
                  _tbRadius
                )
              );

              final distance = _startCursorPosition.distanceTo(_currentCursorPosition);
              final angle = _startCursorPosition.angleTo(_currentCursorPosition);
              final amount = math.max(
                  distance / _tbRadius, angle); //effective rotation angle

              applyTransformMatrix(rotate(
                  calculateRotationAxis(
                      _startCursorPosition, _currentCursorPosition),
                  amount));

              if (enableAnimations) {
                _timePrev = _timeCurrent;
                _timeCurrent = DateTime.now().millisecondsSinceEpoch;
                _anglePrev = _angleCurrent;
                _angleCurrent = amount;
                _cursorPosPrev.setFrom(_cursorPosCurr);
                _cursorPosCurr.setFrom(_currentCursorPosition);
                _wPrev = _wCurr;
                _wCurr = calculateAngularSpeed(
                  _anglePrev,
                  _angleCurrent, 
                  _timePrev, 
                  _timeCurrent
                );
              }
            }
          }

          break;

        case State2.scale:
          if (enableZoom) {
            if (restart) {
              //switch to zoom operation

              dispatchEvent(_endEvent);
              dispatchEvent(_startEvent);

              updateTbState(opState, true);
              _startCursorPosition.setY(
                  getCursorNDC(_center.x, _center.y).y *
                      0.5);
              _currentCursorPosition.setFrom(_startCursorPosition);

              if (enableGrid) {
                disposeGrid();
              }

              activateGizmos(false);
            } else {
              //continue with zoom operation
              const screenNotches = 8; //how many wheel notches corresponds to a full screen pan
              _currentCursorPosition.setY(
                  getCursorNDC(_center.x, _center.y).y *
                      0.5);

              final movement =
                  _currentCursorPosition.y - _startCursorPosition.y;

              double size = 1;

              if (movement < 0) {
                size =
                    1 / (math.pow(scaleFactor, -movement * screenNotches));
              } else if (movement > 0) {
                size = math.pow(scaleFactor, movement * screenNotches).toDouble();
              }

              applyTransformMatrix(
                  scale(size, _gizmos.position));
            }
          }

          break;

        case State2.fov:
          if (enableZoom && camera is PerspectiveCamera) {
            if (restart) {
              //switch to fov operation

              dispatchEvent(_endEvent);
              dispatchEvent(_startEvent);

              updateTbState(opState, true);
              _startCursorPosition.setY(
                  getCursorNDC(_center.x, _center.y).y *
                      0.5);
              _currentCursorPosition.setFrom(_startCursorPosition);

              if (enableGrid) {
                disposeGrid();
              }

              activateGizmos(false);
            } else {
              //continue with fov operation
              const screenNotches = 8; //how many wheel notches corresponds to a full screen pan
              _currentCursorPosition.setY(
                  getCursorNDC(_center.x, _center.y).y *
                      0.5);

              final movement =
                  _currentCursorPosition.y - _startCursorPosition.y;

              double size = 1;

              if (movement < 0) {
                size =
                    1 / (math.pow(scaleFactor, -movement * screenNotches));
              } else if (movement > 0) {
                size = math.pow(scaleFactor, movement * screenNotches).toDouble();
              }

              _v3_1.setFromMatrixPosition(_cameraMatrixState);
              final x = _v3_1.distanceTo(_gizmos.position);
              double xNew = x /size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

              //check min and max distance
              xNew = MathUtils.clamp(xNew, minDistance, maxDistance);

              final y = x * math.tan(MathUtils.deg2rad * _fovState * 0.5);

              //calculate fov
              double newFov = MathUtils.rad2deg * (math.atan(y / xNew) * 2);

              //check min and max fov
              newFov = MathUtils.clamp(newFov, minFov, maxFov);

              final newDistance = y / math.tan(MathUtils.deg2rad * (newFov / 2));
              size = x / newDistance;
              _v3_2.setFromMatrixPosition(_gizmoMatrixState);

              setFov(newFov);
              applyTransformMatrix(scale(size, _v3_2, false));

              //adjusting distance
              _offset
                  .setFrom(_gizmos.position)
                  .sub(camera.position)
                  .normalize()
                  .scale(newDistance / x);
              _m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
            }
          }

          break;
      }

      dispatchEvent(_changeEvent);
    }
  }

  void onSinglePanEnd() {
    if (_state == State2.rotate) {
      if (!enableRotate) {
        return;
      }

      if (enableAnimations) {
        //perform rotation animation
        final deltaTime =
            (DateTime.now().millisecondsSinceEpoch - _timeCurrent);
        if (deltaTime < 120) {
          final w = ((_wPrev + _wCurr) / 2).abs();

          final self = this;
          _animationId = requestAnimationFrame((t) {
            self.updateTbState(State2.animationRotate, true);
            final rotationAxis = self.calculateRotationAxis(
                self._cursorPosPrev, self._cursorPosCurr);

            self.onRotationAnim(t, rotationAxis, math.min(w, self.wMax));
          });
        } else {
          //cursor has been standing still for over 120 ms since last movement
          updateTbState(State2.idle, false);
          activateGizmos(false);
          dispatchEvent(_changeEvent);
        }
      } else {
        updateTbState(State2.idle, false);
        activateGizmos(false);
        dispatchEvent(_changeEvent);
      }
    } else if (_state == State2.pan || _state == State2.idle) {
      updateTbState(State2.idle, false);

      if (enableGrid) {
        disposeGrid();
      }

      activateGizmos(false);
      dispatchEvent(_changeEvent);
    }

    dispatchEvent(_endEvent);
  }

  void onDoubleTap(event) {
    if (enabled && enablePan && scene != null) {
      dispatchEvent(_startEvent);

      setCenter(event.clientX, event.clientY);
      final hitP = unprojectOnObj(
          getCursorNDC(_center.x, _center.y),
          camera);

      if (hitP != null && enableAnimations) {
        final self = this;
        if (_animationId != -1) {
          cancelAnimationFrame(_animationId);
        }

        _timeStart = -1;
        _animationId = requestAnimationFrame((t) {
          self.updateTbState(State2.animationFocus, true);
          self.onFocusAnim(
              t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
        });
      } else if (hitP != null && !enableAnimations) {
        updateTbState(State2.focus, true);
        focus(hitP, scaleFactor);
        updateTbState(State2.idle, false);
        dispatchEvent(_changeEvent);
      }
    }

    dispatchEvent(_endEvent);
  }

  void onDoublePanStart() {
    if (enabled && enablePan) {
      dispatchEvent(_startEvent);

      updateTbState(State2.pan, true);

      setCenter(
          (_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2,
          (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      _startCursorPosition.setFrom(
        unprojectOnTbPlane(
          camera, _center.x, _center.y, true
        )
      );
      _currentCursorPosition.setFrom(_startCursorPosition);

      activateGizmos(false);
    }
  }

  void onDoublePanMove() {
    if (enabled && enablePan) {
      setCenter(
          (_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2,
          (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);

      if (_state != State2.pan) {
        updateTbState(State2.pan, true);
        _startCursorPosition.setFrom(_currentCursorPosition);
      }

      _currentCursorPosition.setFrom(
        unprojectOnTbPlane(
          camera, _center.x, _center.y, true
        )
      );
      applyTransformMatrix(pan(_startCursorPosition, _currentCursorPosition, true));
      dispatchEvent(_changeEvent);
    }
  }

  void onDoublePanEnd(event) {
    updateTbState(State2.idle, false);
    dispatchEvent(_endEvent);
  }

  void onRotateStart() {
    if (enabled && enableRotate) {
      dispatchEvent(_startEvent);

      updateTbState(State2.zRotate, true);

      //_startFingerRotation = event.rotation;

      _startFingerRotation =
          getAngle(_touchCurrent[1], _touchCurrent[0]) +
              getAngle(_touchStart[1], _touchStart[0]);
      _currentFingerRotation = _startFingerRotation;

      camera.getWorldDirection(_rotationAxis); //rotation axis

      if (!enablePan && !enableZoom) {
        activateGizmos(true);
      }
    }
  }

  void onRotateMove() {
    if (enabled && enableRotate) {
      setCenter(
          (_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2,
          (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      dynamic rotationPoint;

      if (_state != State2.zRotate) {
        updateTbState(State2.zRotate, true);
        _startFingerRotation = _currentFingerRotation;
      }

      //_currentFingerRotation = event.rotation;
      _currentFingerRotation = getAngle(_touchCurrent[1], _touchCurrent[0]) + getAngle(_touchStart[1], _touchStart[0]);

      if (!enablePan) {
        rotationPoint =
            Vector3().setFromMatrixPosition(_gizmoMatrixState);
      } else {
        _v3_2.setFromMatrixPosition(_gizmoMatrixState);
        rotationPoint = unprojectOnTbPlane(camera, _center.x, _center.y)
            .applyQuaternion(camera.quaternion)
            .scale(1 / camera.zoom)
            .add(_v3_2);
      }

      final amount = MathUtils.deg2rad *
          (_startFingerRotation - _currentFingerRotation);

      applyTransformMatrix(zRotate(rotationPoint, amount));
      dispatchEvent(_changeEvent);
    }
  }

  onRotateEnd(event) {
    updateTbState(State2.idle, false);
    activateGizmos(false);
    dispatchEvent(_endEvent);
  }

  onPinchStart() {
    if (enabled && enableZoom) {
      dispatchEvent(_startEvent);
      updateTbState(State2.scale, true);

      _startFingerDistance = calculatePointersDistance(
          _touchCurrent[0], _touchCurrent[1]);
      _currentFingerDistance = _startFingerDistance;

      activateGizmos(false);
    }
  }

  void onPinchMove() {
    if (enabled && enableZoom) {
      setCenter(
          (_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2,
          (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      const minDistance = 12; //minimum distance between fingers (in css pixels)

      if (_state != State2.scale) {
        _startFingerDistance = _currentFingerDistance;
        updateTbState(State2.scale, true);
      }

      _currentFingerDistance = math.max(
          calculatePointersDistance(
            _touchCurrent[0], 
            _touchCurrent[1]
          ),
          minDistance * _devPxRatio
        );
      final amount = _currentFingerDistance / _startFingerDistance;

      Vector3? scalePoint;

      if (!enablePan) {
        scalePoint = _gizmos.position;
      } 
      else {
        if (camera is OrthographicCamera) {
          scalePoint = unprojectOnTbPlane(camera, _center.x, _center.y)
              .applyQuaternion(camera.quaternion)
              .scale(1 / camera.zoom)
              .add(_gizmos.position);
        } 
        else if (camera is PerspectiveCamera) {
          scalePoint = unprojectOnTbPlane(camera, _center.x, _center.y)
              .applyQuaternion(camera.quaternion)
              .add(_gizmos.position);
        }
      }

      applyTransformMatrix(scale(amount, scalePoint));
      dispatchEvent(_changeEvent);
    }
  }

  void onPinchEnd(event) {
    updateTbState(State2.idle, false);
    dispatchEvent(_endEvent);
  }

  void onTriplePanStart(event) {
    if (enabled && enableZoom) {
      dispatchEvent(_startEvent);

      updateTbState(State2.scale, true);

      //final center = event.center;
      num clientX = 0;
      num clientY = 0;
      final nFingers = _touchCurrent.length;

      for (int i = 0; i < nFingers; i++) {
        clientX += _touchCurrent[i]!.clientX;
        clientY += _touchCurrent[i]!.clientY;
      }

      setCenter(clientX / nFingers, clientY / nFingers);

      _startCursorPosition.setY(
          getCursorNDC(_center.x, _center.y).y * 0.5);
      _currentCursorPosition.setFrom(_startCursorPosition);
    }
  }

  void onTriplePanMove(event) {
    if (enabled && enableZoom) {
      //	  fov / 2
      //		|\
      //		| \
      //		|  \
      //	x	|	\
      //		| 	 \
      //		| 	  \
      //		| _ _ _\
      //			y

      //final center = event.center;
      num clientX = 0;
      num clientY = 0;
      final nFingers = _touchCurrent.length;

      for (int i = 0; i < nFingers; i++) {
        clientX += _touchCurrent[i].clientX;
        clientY += _touchCurrent[i].clientY;
      }

      setCenter(clientX / nFingers, clientY / nFingers);

      const screenNotches = 8; //how many wheel notches corresponds to a full screen pan
      _currentCursorPosition.setY(
          getCursorNDC(_center.x, _center.y).y * 0.5);

      final movement =
          _currentCursorPosition.y - _startCursorPosition.y;

      double size = 1;

      if (movement < 0) {
        size = 1 / (math.pow(scaleFactor, -movement * screenNotches));
      } 
      else if (movement > 0) {
        size = math.pow(scaleFactor, movement * screenNotches).toDouble();
      }

      _v3_1.setFromMatrixPosition(_cameraMatrixState);
      final x = _v3_1.distanceTo(_gizmos.position);
      double xNew = x /size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

      //check min and max distance
      xNew = MathUtils.clamp(xNew, minDistance, maxDistance);

      final y = x * math.tan(MathUtils.deg2rad * _fovState * 0.5);

      //calculate fov
      double newFov = MathUtils.rad2deg * (math.atan(y / xNew) * 2);

      //check min and max fov
      newFov = MathUtils.clamp(newFov, minFov, maxFov);

      final newDistance = y / math.tan(MathUtils.deg2rad * (newFov / 2));
      size = x / newDistance;
      _v3_2.setFromMatrixPosition(_gizmoMatrixState);

      setFov(newFov);
      applyTransformMatrix(scale(size, _v3_2, false));

      //adjusting distance
      _offset
          .setFrom(_gizmos.position)
          .sub(camera.position)
          .normalize()
          .scale(newDistance / x);
      _m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);

      dispatchEvent(_changeEvent);
    }
  }

  void onTriplePanEnd() {
    updateTbState(State2.idle, false);
    dispatchEvent(_endEvent);
    //dispatchEvent( _changeEvent );
  }

	/// Set _center's x/y coordinates
  void setCenter(double clientX, double clientY) {
    _center.x = clientX;
    _center.y = clientY;
  }

	/// Set default mouse actions
  void initializeMouseActions() {
    setMouseAction('pan', 0, 'CTRL');
    setMouseAction('pan', 2);

    setMouseAction('rotate', 0);

    setMouseAction('ZOOM', 3);
    setMouseAction('ZOOM', 1);

    setMouseAction('fov', 3, 'SHIFT');
    setMouseAction('fov', 1, 'SHIFT');
  }

	/// Compare two mouse actions
	/// returns bool True if action1 and action 2 are the same mouse action, false otherwise
  bool compareMouseAction(action1, action2) {
    if (action1['operation'] == action2['operation']) {
      if (action1['mouse'] == action2['mouse'] &&
          action1['key'] == action2['key']) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

	/// * Set a mouse action by specifying the operation to be performed and a mouse/key combination. In case of conflict, replaces the existing one
	/// * [operation] The operation to be performed ('pan', 'rotate', 'ZOOM', 'fov)
	/// * [mouse] A mouse button (0, 1, 2, 3) or for wheel notches
	/// * [key] The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
	/// * returns Boolean True if the mouse action has been successfully added, false otherwise
  bool setMouseAction(String operation, int mouse, [String? key]) {
    final operationInput = ['pan', 'rotate', 'ZOOM', 'fov'];
    final mouseInput = ['0', '1', '2', '3'];
    final keyInput = ['CTRL', 'SHIFT', null];
    int? state;

    if (
      !operationInput.contains(operation) ||
      !mouseInput.contains(mouse.toString()) ||
      !keyInput.contains(key)
    ) {
      //invalid parameters
      return false;
    }

    if (mouse == 3) {
      if (operation != 'ZOOM' && operation != 'fov') {
        //cannot associate 2D operation to 1D input
        return false;
      }
    }

    switch (operation) {
      case 'pan':
        state = State2.pan;
        break;

      case 'rotate':
        state = State2.rotate;
        break;

      case 'ZOOM':
        state = State2.scale;
        break;

      case 'fov':
        state = State2.fov;
        break;
    }

    final action = {
      'operation': operation,
      'mouse': mouse,
      'key': key,
      'state': state
    };

    for (int i = 0; i < mouseActions.length; i++) {
      if (
        mouseActions[i]['mouse'] == action['mouse'] &&
        mouseActions[i]['key'] == action['key']
      ) {
        mouseActions.replaceRange(i, i+1, [action]);
        return true;
      }
    }

    mouseActions.add(action);
    return true;
  }

	/// * Remove a mouse action by specifying its mouse/key combination
	/// * [mouse] A mouse button (0, 1, 2, 3) 3 for wheel notches
	/// * [key] The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
	/// * returns Boolean True if the operation has been succesfully removed, false otherwise
  bool unsetMouseAction(mouse, [String? key]) {
    for (int i = 0; i < mouseActions.length; i++) {
      if (
        mouseActions[i]['mouse'] == mouse &&
        mouseActions[i]['key'] == key
      ) {
        mouseActions.removeAt(i);
        return true;
      }
    }

    return false;
  }

	/// * Return the operation associated to a mouse/keyboard combination
	/// * [mouse] A mouse button (0, 1, 2, 3) 3 for wheel notches
	/// * [key] The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
	/// * returns The operation if it has been found, null otherwise
  String? getOpFromAction(int mouse, String? key) {
    Map<String,dynamic> action;

    for (int i = 0; i < mouseActions.length; i++) {
      action = mouseActions[i];
      if (action['mouse'] == mouse && action['key'] == key) {
        return action['operation'];
      }
    }

    if (key != null) {
      for (int i = 0; i < mouseActions.length; i++) {
        action = mouseActions[i];
        if (action['mouse'] == mouse && action['key'] == null) {
          return action['operation'];
        }
      }
    }

    return null;
  }

	/// * Get the operation associated to mouse and key combination and returns the corresponding FSA state
	/// * [mouse] Mouse button
	/// * [key] Keyboard modifier
	/// * returns The FSA state obtained from the operation associated to mouse/keyboard combination
  int? getOpStateFromAction(int mouse, String? key) {
    Map<String,dynamic> action;

    for (int i = 0; i < mouseActions.length; i++) {
      action = mouseActions[i];
      if (action['mouse'] == mouse && action['key'] == key) {
        return action['state'];
      }
    }

    if (key != null) {
      for (int i = 0; i < mouseActions.length; i++) {
        action = mouseActions[i];
        if (action['mouse'] == mouse && action['key'] == null) {
          return action['state'];
        }
      }
    }

    return null;
  }

	/// Calculate the angle between two pointers
	/// returns double The angle between two pointers in degrees
  double getAngle(p1, p2) {
    return math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX) *180 /math.pi;
  }

	/// Update a PointerEvent inside current pointerevents array
  void updateTouchEvent(event) {
    for (int i = 0; i < _touchCurrent.length; i++) {
      if (_touchCurrent[i].pointerId == event.pointerId) {
        _touchCurrent.replaceRange(i, i+1, [event]);
        break;
      }
    }
  }

	/// * Apply a transformation matrix, to the camera and gizmos
	/// * [transformation] Object containing matrices to apply to camera and gizmos
  void applyTransformMatrix(Map<String, Matrix4>? transformation) {
    if (transformation?['camera'] != null) {
      _m4_1.setFrom(_cameraMatrixState).premultiply(transformation!['camera']!);
      _m4_1.decompose(camera.position, camera.quaternion, camera.scale);
      camera.updateMatrix();

      //update camera up vector
      if (
        _state == State2.rotate ||
        _state == State2.zRotate ||
        _state == State2.animationRotate
      ){
        camera.up.setFrom(_upState).applyQuaternion(camera.quaternion);
      }
    }

    if (transformation?['gizmos'] != null) {
      _m4_1.setFrom(_gizmoMatrixState).premultiply(transformation!['gizmos']!);
      _m4_1.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
      _gizmos.updateMatrix();
    }

    if (_state == State2.scale ||
        _state == State2.focus ||
        _state == State2.animationFocus) {
      _tbRadius = calculateTbRadius(camera);

      if (adjustNearFar) {
        final cameraDistance =
            camera.position.distanceTo(_gizmos.position);

        final bb = BoundingBox();
        bb.setFromObject(_gizmos);
        final sphere = BoundingSphere();
        bb.getBoundingSphere(sphere);

        final adjustedNearPosition =
            math.max(_nearPos0, sphere.radius + sphere.center.length);
        final regularNearPosition = cameraDistance - _initialNear;

        final minNearPos = math.min(adjustedNearPosition, regularNearPosition);
        camera.near = cameraDistance - minNearPos;

        final adjustedFarPosition =
            math.min(_farPos0, -sphere.radius + sphere.center.length);
        final regularFarPosition = cameraDistance - _initialFar;

        final minFarPos = math.min(adjustedFarPosition, regularFarPosition);
        camera.far = cameraDistance - minFarPos;

        camera.updateProjectionMatrix();
      } 
      else {
        bool update = false;

        if (camera.near != _initialNear) {
          camera.near = _initialNear;
          update = true;
        }

        if (camera.far != _initialFar) {
          camera.far = _initialFar;
          update = true;
        }

        if (update) {
          camera.updateProjectionMatrix();
        }
      }
    }
  }

	/// * Calculate the angular speed
	/// * [p0] Position at t0
	/// * [p1] Position at t1
	/// * [t0] Initial time in milliseconds
	/// * [t1] Ending time in milliseconds
  double calculateAngularSpeed(p0, p1, t0, t1) {
    final s = p1 - p0;
    final t = (t1 - t0) / 1000;
    if (t == 0) {
      return 0;
    }

    return s / t;
  }

	/// * Calculate the distance between two pointers
	/// * [p0] The first pointer
	/// * [p1] The second pointer
	/// * returns double The distance between the two pointers
  double calculatePointersDistance(p0, p1) {
    return math.sqrt(math.pow(p1.clientX - p0.clientX, 2) +
        math.pow(p1.clientY - p0.clientY, 2));
  }

	/// * Calculate the rotation axis as the vector perpendicular between two vectors
	/// * [vec1] The first vector
	/// * [vec2] The second vector
	/// * returns Vector3 The normalized rotation axis
  Vector3 calculateRotationAxis(Vector3 vec1, Vector3 vec2) {
    _rotationMatrix.extractRotation(_cameraMatrixState);
    _quat.setFromRotationMatrix(_rotationMatrix);

    _rotationAxis.cross2(vec1, vec2).applyQuaternion(_quat);
    return _rotationAxis.normalize().clone();
  }

	/// * Calculate the trackball radius so that gizmo's diamater will be 2/3 of the minimum side of the camera frustum
	/// * returns double The trackball radius
  double calculateTbRadius(Camera camera) {
    final distance = camera.position.distanceTo(_gizmos.position);

    if (camera is PerspectiveCamera) {
      final halfFovV = MathUtils.deg2rad * camera.fov * 0.5; //vertical fov/2 in radians
      final halfFovH = math.atan((camera.aspect) * math.tan(halfFovV)); //horizontal fov/2 in radians
      return math.tan(math.min(halfFovV, halfFovH)) *distance *radiusFactor;
    } 
    else if (camera is OrthographicCamera) {
      return math.min(camera.top, camera.right) * radiusFactor;
    }

    return 0;
  }

	/// * Focus operation consist of positioning the point of interest in front of the camera and a slightly zoom in
	/// * [point] The point of interest
	/// * [size] Scale factor
	/// * [amount] amount of operation to be completed (used for focus animations, default is complete full operation)
  void focus(point, size, [num amount = 1]) {
    //move center of camera (along with gizmos) towards point of interest
    _offset.setFrom(point).sub(_gizmos.position).scale(amount);
    _translationMatrix.makeTranslation(_offset.x, _offset.y, _offset.z);

    _gizmoMatrixStateTemp.setFrom(_gizmoMatrixState);
    _gizmoMatrixState.premultiply(_translationMatrix);
    _gizmoMatrixState.decompose(
        _gizmos.position, _gizmos.quaternion, _gizmos.scale);

    _cameraMatrixStateTemp.setFrom(_cameraMatrixState);
    _cameraMatrixState.premultiply(_translationMatrix);
    _cameraMatrixState.decompose(
        camera.position, camera.quaternion, camera.scale);

    //apply zoom
    if (enableZoom) {
      applyTransformMatrix(scale(size, _gizmos.position));
    }

    _gizmoMatrixState.setFrom(_gizmoMatrixStateTemp);
    _cameraMatrixState.setFrom(_cameraMatrixStateTemp);
  }

	/// Draw a grid and add it to the scene
	/// 
  void drawGrid() {
    if (scene != null) {
      const color = 0x888888;
      const multiplier = 3;
      double? size;
      double? divisions;
      double maxLength;
      double tick;

      if (camera is OrthographicCamera) {
        final width = camera.right - camera.left;
        final height = camera.bottom - camera.top;

        maxLength = math.max(width, height);
        tick = maxLength / 20;

        size = maxLength / camera.zoom * multiplier;
        divisions = size / tick * camera.zoom;
      } 
      else if (camera is PerspectiveCamera) {
        final distance = camera.position.distanceTo(_gizmos.position);
        final halfFovV = MathUtils.deg2rad * camera.fov * 0.5;
        final halfFovH = math.atan((camera.aspect) * math.tan(halfFovV));

        maxLength = math.tan(math.max(halfFovV, halfFovH)) * distance * 2;
        tick = maxLength / 20;

        size = maxLength * multiplier;
        divisions = size / tick;
      }

      if (_grid == null && size != null && divisions != null) {
        _grid = GridHelper(size, divisions.toInt(), color, color);
        _grid!.position.setFrom(_gizmos.position);
        _gridPosition.setFrom(_grid!.position);
        _grid!.quaternion.setFrom(camera.quaternion);
        _grid!.rotateX(math.pi * 0.5);

        scene!.add(_grid);
      }
    }
  }
  void disconnect(){
    domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    domElement.removeEventListener(PeripheralType.pointercancel, onPointerCancel);
    domElement.removeEventListener(PeripheralType.wheel, onWheel);
    domElement.removeEventListener(PeripheralType.contextmenu, onContextMenu);
    domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
    domElement.removeEventListener(PeripheralType.pointerup, onPointerUp);
    domElement.removeEventListener(PeripheralType.resize, onWindowResize);
  }
	/// Remove all listeners, stop animations and clean scene
	///
  void dispose() {
    if(disposed) return;
    disposed = true;
    if (_animationId != -1) {
      cancelAnimationFrame(_animationId);
    }

    clearListeners();

    if (scene != null) scene!.remove(_gizmos);
    _gizmos.dispose();
    disposeGrid();

    _m4_1.dispose();
    _m4_2.dispose();
    _translationMatrix.dispose();
    _rotationMatrix.dispose();
    _scaleMatrix.dispose();
    _cameraMatrixState.dispose();
    _cameraProjectionState.dispose();
    _gizmoMatrixState.dispose();
    _cameraMatrixState0.dispose();
    _gizmoMatrixState0.dispose();
  }
	/// remove the grid from the scene
	///
  void disposeGrid() {
    if (_grid != null && scene != null) {
      scene!.remove(_grid!);
      _grid = null;
    }
  }

	/// * Compute the easing out cubic function for ease out effect in animation
	/// * @param {Number} t The absolute progress of the animation in the bound of 0 (beginning of the) and 1 (ending of animation)
	/// * @returns {Number} Result of easing out cubic at time t
  num easeOutCubic(t) {
    return 1 - math.pow(1 - t, 3);
  }

	/// * Make rotation gizmos more or less visible
	/// * [isActive] If true, make gizmos more visible
  void activateGizmos(isActive) {
    final gizmoX = _gizmos.children[0];
    final gizmoY = _gizmos.children[1];
    final gizmoZ = _gizmos.children[2];

    if (isActive) {
      gizmoX.material?.setValues({MaterialProperty.opacity: 1.0});
      gizmoY.material?.setValues({MaterialProperty.opacity: 1.0});
      gizmoZ.material?.setValues({MaterialProperty.opacity: 1.0});
    } else {
      gizmoX.material?.setValues({MaterialProperty.opacity: 0.6});
      gizmoY.material?.setValues({MaterialProperty.opacity: 0.6});
      gizmoZ.material?.setValues({MaterialProperty.opacity: 0.6});
    }
  }

	/// * Calculate the cursor position in NDC
	/// * [cursorX] Cursor horizontal coordinate within the canvas
	/// * [cursorY] Cursor vertical coordinate within the canvas
	/// * @ Vector2 Cursor normalized position inside the canvas
  Vector2 getCursorNDC(double cursorX, double cursorY) {
    // final canvasRect = canvas.getBoundingClientRect();

    final box = listenableKey.currentContext!.findRenderObject() as RenderBox;
    final canvasRect = box.size;
    final local = box.globalToLocal(const Offset(0, 0));

    _v2_1.setX(((cursorX - local.dx) / canvasRect.width) * 2 - 1);
    _v2_1.setY((((local.dy + canvasRect.height) - cursorY) / canvasRect.height) * 2 - 1);
    return _v2_1.clone();
  }

	/// * Calculate the cursor position inside the canvas x/y coordinates with the origin being in the center of the canvas
	/// * [cursorX] Cursor horizontal coordinate within the canvas
	/// * [cursorY] Cursor vertical coordinate within the canvas
	/// * returns Vector2 Cursor position inside the canvas
  Vector2 getCursorPosition(double cursorX, double cursorY) {
    _v2_1.setFrom(getCursorNDC(cursorX, cursorY));
    _v2_1.x *= (camera.right - camera.left) * 0.5;
    _v2_1.y *= (camera.top - camera.bottom) * 0.5;
    return _v2_1.clone();
  }

	/// * Set the camera to be controlled
	/// * [camera] The virtual camera to be controlled
  void setCamera(camera) {
    camera.lookAt(target);
    camera.updateMatrix();

    //setting state
    if (camera.type == 'PerspectiveCamera') {
      _fov0 = camera.fov;
      _fovState = camera.fov;
    }

    _cameraMatrixState0.setFrom(camera.matrix);
    _cameraMatrixState.setFrom(_cameraMatrixState0);
    _cameraProjectionState.setFrom(camera.projectionMatrix);
    _zoom0 = camera.zoom;
    _zoomState = _zoom0;

    _initialNear = camera.near;
    _nearPos0 = camera.position.distanceTo(target) - camera.near;
    _nearPos = _initialNear;

    _initialFar = camera.far;
    _farPos0 = camera.position.distanceTo(target) - camera.far;
    _farPos = _initialFar;

    _up0.setFrom(camera.up);
    _upState.setFrom(camera.up);

    camera = camera;
    camera.updateProjectionMatrix();

    //making gizmos
    _tbRadius = calculateTbRadius(camera);
    makeGizmos(target, _tbRadius);
  }

	/// * Set gizmos visibility
	/// * [value] Value of gizmos visibility
  void setGizmosVisible(value) {
    _gizmos.visible = value;
    dispatchEvent(_changeEvent);
  }

	/// * Set gizmos radius factor and redraws gizmos
	/// * [value] Value of radius factor
  void setTbRadius(value) {
    radiusFactor = value;
    _tbRadius = calculateTbRadius(camera);

    final curve = EllipseCurve(0, 0, _tbRadius, _tbRadius);
    final points = curve.getPoints(_curvePts);
    final curveGeometry = BufferGeometry().setFromPoints(points);

    for (final gizmo in _gizmos.children) {
      // _gizmos.children[ gizmo ].geometry = curveGeometry;
      gizmo.geometry = curveGeometry;
    }

    dispatchEvent(_changeEvent);
  }

	/// * Creates the rotation gizmos matching trackball center and radius
	/// * [tbCenter] The trackball center
	/// * [tbRadius] The trackball radius
  void makeGizmos(tbCenter, tbRadius) {
    final curve = EllipseCurve(0, 0, tbRadius, tbRadius);
    final points = curve.getPoints(_curvePts);

    //geometry
    final curveGeometry = BufferGeometry().setFromPoints(points);

    //material
    final curveMaterialX = LineBasicMaterial.fromMap({'color': 0xff8080, 'fog': false, 'transparent': true, 'opacity': 0.6});
    final curveMaterialY = LineBasicMaterial.fromMap({'color': 0x80ff80, 'fog': false, 'transparent': true, 'opacity': 0.6});
    final curveMaterialZ = LineBasicMaterial.fromMap({'color': 0x8080ff, 'fog': false, 'transparent': true, 'opacity': 0.6});

    //line
    final gizmoX = Line(curveGeometry, curveMaterialX);
    final gizmoY = Line(curveGeometry, curveMaterialY);
    final gizmoZ = Line(curveGeometry, curveMaterialZ);

    const rotation = math.pi * 0.5;
    gizmoX.rotation.x = rotation;
    gizmoY.rotation.y = rotation;

    //setting state
    _gizmoMatrixState0.identity().setPosition(tbCenter.x, tbCenter.y, tbCenter.z);
    _gizmoMatrixState.setFrom(_gizmoMatrixState0);

    if (camera.zoom != 1) {
      //adapt gizmos size to camera zoom
      final size = 1 / camera.zoom;
      _scaleMatrix.makeScale(size, size, size);
      _translationMatrix.makeTranslation(-tbCenter.x, -tbCenter.y, -tbCenter.z);

      _gizmoMatrixState.premultiply(_translationMatrix).premultiply(_scaleMatrix);
      _translationMatrix.makeTranslation(tbCenter.x, tbCenter.y, tbCenter.z);
      _gizmoMatrixState.premultiply(_translationMatrix);
    }

    _gizmoMatrixState.decompose(
        _gizmos.position, _gizmos.quaternion, _gizmos.scale);

    _gizmos.clear();

    _gizmos.add(gizmoX);
    _gizmos.add(gizmoY);
    _gizmos.add(gizmoZ);
  }

  /// *
	/// * Perform animation for focus operation
	/// * @param {Number} time Instant in which this function is called as performance.now()
	/// * @param {Vector3} point Point of interest for focus operation
	/// * @param {Matrix4} cameraMatrix Camera matrix
	/// * @param {Matrix4} gizmoMatrix Gizmos matrix
	/// *
  void onFocusAnim(time, point, cameraMatrix, gizmoMatrix) {
    if (_timeStart == -1) {
      //animation start
      _timeStart = time;
    }

    if (_state == State2.animationFocus) {
      final deltaTime = time - _timeStart;
      final animTime = deltaTime / focusAnimationTime;

      _gizmoMatrixState.setFrom(gizmoMatrix);

      if (animTime >= 1) {
        //animation end

        _gizmoMatrixState.decompose(
            _gizmos.position, _gizmos.quaternion, _gizmos.scale);

        focus(point, scaleFactor);

        _timeStart = -1;
        updateTbState(State2.idle, false);
        activateGizmos(false);

        dispatchEvent(_changeEvent);
      } 
      else {
        num amount = easeOutCubic(animTime);
        final size = ((1 - amount) + (scaleFactor * amount));

        _gizmoMatrixState.decompose(
            _gizmos.position, _gizmos.quaternion, _gizmos.scale);
        focus(point, size, amount);

        dispatchEvent(_changeEvent);
        final self = this;
        _animationId = requestAnimationFrame((t) {
          self.onFocusAnim(t, point, cameraMatrix, gizmoMatrix.clone());
        });
      }
    } else {
      //interrupt animation

      _animationId = -1;
      _timeStart = -1;
    }
  }

  /// *
	/// * Perform animation for rotation operation
	/// * @param {Number} time Instant in which this function is called as performance.now()
	/// * @param {Vector3} rotationAxis Rotation axis
	/// * @param {number} w0 Initial angular velocity
	/// *
  void onRotationAnim(time, rotationAxis, w0) {
    if (_timeStart == -1) {
      //animation start
      _anglePrev = 0;
      _angleCurrent = 0;
      _timeStart = time;
    }

    if (_state == State2.animationRotate) {
      //w = w0 + alpha * t
      final deltaTime = (time - _timeStart) / 1000;
      final w = w0 + ((-dampingFactor) * deltaTime);

      if (w > 0) {
        //tetha = 0.5 * alpha * t^2 + w0 * t + tetha0
        _angleCurrent =
            0.5 * (-dampingFactor) * math.pow(deltaTime, 2) +
                w0 * deltaTime +
                0;
        applyTransformMatrix(rotate(rotationAxis, _angleCurrent));
        dispatchEvent(_changeEvent);
        final self = this;
        _animationId = requestAnimationFrame((t) {
          self.onRotationAnim(t, rotationAxis, w0);
        });
      } else {
        _animationId = -1;
        _timeStart = -1;

        updateTbState(State2.idle, false);
        activateGizmos(false);

        dispatchEvent(_changeEvent);
      }
    } else {
      //interrupt animation

      _animationId = -1;
      _timeStart = -1;

      if (_state != State2.rotate) {
        activateGizmos(false);
        dispatchEvent(_changeEvent);
      }
    }
  }

  /// *
	/// * Perform pan operation moving camera between two points
	/// * @param {Vector3} p0 Initial point
	/// * @param {Vector3} p1 Ending point
	/// * @param {Boolean} adjust If movement should be adjusted considering camera distance (Perspective only)
	/// *
  Map<String, Matrix4> pan(Vector3 p0, Vector3 p1, [bool adjust = false]) {
    final movement = p0.clone().sub(p1);

    if (camera is OrthographicCamera) {
      //adjust movement amount
      movement.scale(1 / camera.zoom);
    } 
    else if (camera is PerspectiveCamera && adjust) {
      //adjust movement amount
      _v3_1.setFromMatrixPosition(
          _cameraMatrixState0); //camera's initial position
      _v3_2.setFromMatrixPosition(
          _gizmoMatrixState0); //gizmo's initial position
      final distanceFactor = _v3_1.distanceTo(_v3_2) /
          camera.position.distanceTo(_gizmos.position);
      movement.scale(1 / distanceFactor);
    }

    _v3_1
        .setValues(movement.x, movement.y, 0)
        .applyQuaternion(camera.quaternion);

    _m4_1.makeTranslation(_v3_1.x, _v3_1.y, _v3_1.z);

    setTransformationMatrices(_m4_1, _m4_1);
    return _transformation;
  }

	/// Reset trackball
	///
  void reset() {
    camera.zoom = _zoom0;

    if (camera is PerspectiveCamera) {
      camera.fov = _fov0;
    }

    camera.near = _nearPos;
    camera.far = _farPos;
    _cameraMatrixState.setFrom(_cameraMatrixState0);
    _cameraMatrixState.decompose(
        camera.position, camera.quaternion, camera.scale);
    camera.up.setFrom(_up0);

    camera.updateMatrix();
    camera.updateProjectionMatrix();

    _gizmoMatrixState.setFrom(_gizmoMatrixState0);
    _gizmoMatrixState0.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
    _gizmos.updateMatrix();

    _tbRadius = calculateTbRadius(camera);
    makeGizmos(_gizmos.position, _tbRadius);

    camera.lookAt(_gizmos.position);

    updateTbState(State2.idle, false);

    dispatchEvent(_changeEvent);
  }

	/// * Rotate the camera around an axis passing by trackball's center
	/// * [axis] Rotation axis
	/// * [angle] Angle in radians
	/// * returns Object Object with 'camera' field containing transformation matrix resulting from the operation to be applied to the camera
  Map<String, Matrix4> rotate(Vector3 axis, double angle) {
    final point = _gizmos.position; //rotation center
    _translationMatrix.makeTranslation(-point.x, -point.y, -point.z);
    _rotationMatrix.makeRotationAxis(axis, -angle);

    //rotate camera
    _m4_1.makeTranslation(point.x, point.y, point.z);
    _m4_1.multiply(_rotationMatrix);
    _m4_1.multiply(_translationMatrix);

    setTransformationMatrices(_m4_1);

    return _transformation;
  }

  void copyState() {
    // final state;
    // if ( camera is OrthographicCamera ) {

    // 	state = JSON.stringify( { 'arcballState': {

    // 		'cameraFar': camera.far,
    // 		'cameraMatrix': camera.matrix,
    // 		'cameraNear': camera.near,
    // 		'cameraUp': camera.up,
    // 		'cameraZoom': camera.zoom,
    // 		'gizmoMatrix': _gizmos.matrix

    // 	} } );

    // } else if ( camera is PerspectiveCamera ) {

    // 	state = JSON.stringify( { 'arcballState': {
    // 		'cameraFar': camera.far,
    // 		'cameraFov': camera.fov,
    // 		'cameraMatrix': camera.matrix,
    // 		'cameraNear': camera.near,
    // 		'cameraUp': camera.up,
    // 		'cameraZoom': camera.zoom,
    // 		'gizmoMatrix': _gizmos.matrix

    // 	} } );

    // }

    // navigator.clipboard.writeText( state );
  }

  void pasteState() {
    // final self = this;
    // navigator.clipboard.readText().then( function resolved( value ) {

    // 	self.setStateFromJSON( value );

    // } );
  }

	/// Save the current state of the control. This can later be recover with .reset
	///
  void saveState() {
    _cameraMatrixState0.setFrom(camera.matrix);
    _gizmoMatrixState0.setFrom(_gizmos.matrix);
    _nearPos = camera.near;
    _farPos = camera.far;
    _zoom0 = camera.zoom;
    _up0.setFrom(camera.up);

    if (camera is PerspectiveCamera) {
      _fov0 = camera.fov;
    }
  }

	/// * Perform uniform scale operation around a given point
	/// * [size] Scale factor
	/// * [point] Point around which scale
	/// * [scaleGizmos] If gizmos should be scaled (Perspective only)
	/// * returns Object Object with 'camera' and 'gizmo' fields containing transformation matrices resulting from the operation to be applied to the camera and gizmos
  Map<String, Matrix4>? scale(double size, Vector? point, [bool scaleGizmos = true]) {
    _scalePointTemp.setFrom(point ?? Vector3());
    double sizeInverse = 1 / size;

    if (camera is OrthographicCamera) {
      //camera zoom
      camera.zoom = _zoomState;
      camera.zoom *= size;

      //check min and max zoom
      if (camera.zoom > maxZoom) {
        camera.zoom = maxZoom;
        sizeInverse = _zoomState / maxZoom;
      } 
      else if (camera.zoom < minZoom) {
        camera.zoom = minZoom;
        sizeInverse = _zoomState / minZoom;
      }

      camera.updateProjectionMatrix();

      _v3_1
          .setFromMatrixPosition(_gizmoMatrixState); //gizmos position

      //scale gizmos so they appear in the same spot having the same dimension
      _scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);
      _translationMatrix
          .makeTranslation(-_v3_1.x, -_v3_1.y, -_v3_1.z);

      _m4_2
          .makeTranslation(_v3_1.x, _v3_1.y, _v3_1.z)
          .multiply(_scaleMatrix);
      _m4_2.multiply(_translationMatrix);

      //move camera and gizmos to obtain pinch effect
      _scalePointTemp.sub(_v3_1);

      final amount = _scalePointTemp.clone().scale(sizeInverse);
      _scalePointTemp.sub(amount);

      _m4_1.makeTranslation(
          _scalePointTemp.x, _scalePointTemp.y, _scalePointTemp.z);
      _m4_2.premultiply(_m4_1);

      setTransformationMatrices(_m4_1, _m4_2);
      return _transformation;
    } 
    else if (camera is PerspectiveCamera) {
      _v3_1.setFromMatrixPosition(_cameraMatrixState);
      _v3_2.setFromMatrixPosition(_gizmoMatrixState);

      //move camera
      num distance = _v3_1.distanceTo(_scalePointTemp);
      num amount = distance - (distance * sizeInverse);

      //check min and max distance
      final newDistance = distance - amount;
      if (newDistance < minDistance) {
        sizeInverse = minDistance / distance;
        amount = distance - (distance * sizeInverse);
      } else if (newDistance > maxDistance) {
        sizeInverse = maxDistance / distance;
        amount = distance - (distance * sizeInverse);
      }

      _offset
          .setFrom(_scalePointTemp)
          .sub(_v3_1)
          .normalize()
          .scale(amount);

      _m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);

      if (scaleGizmos) {
        //scale gizmos so they appear in the same spot having the same dimension
        final pos = _v3_2;

        distance = pos.distanceTo(_scalePointTemp);
        amount = distance - (distance * sizeInverse);
        _offset
            .setFrom(_scalePointTemp)
            .sub(_v3_2)
            .normalize()
            .scale(amount);

        _translationMatrix.makeTranslation(pos.x, pos.y, pos.z);
        _scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);

        _m4_2
            .makeTranslation(_offset.x, _offset.y, _offset.z)
            .multiply(_translationMatrix);
        _m4_2.multiply(_scaleMatrix);

        _translationMatrix.makeTranslation(-pos.x, -pos.y, -pos.z);

        _m4_2.multiply(_translationMatrix);
        setTransformationMatrices(_m4_1, _m4_2);
      } else {
        setTransformationMatrices(_m4_1);
      }

      return _transformation;
    }

    return null;
  }

	/// * Set camera fov
	/// * [value] fov to be setted
  void setFov(double value) {
    if (camera is PerspectiveCamera) {
      camera.fov = MathUtils.clamp(value, minFov, maxFov);
      camera.updateProjectionMatrix();
    }
  }

	/// * Set values in transformation object
	/// * [camera] Transformation to be applied to the camera
	/// * [gizmos] Transformation to be applied to gizmos
  void setTransformationMatrices([Matrix4? camera, Matrix4? gizmos]) {
    if (camera != null) {
      if (_transformation['camera'] != null) {
        _transformation['camera']!.setFrom(camera);
      } 
      else {
        _transformation['camera'] = camera.clone();
      }
    } 
    else {
      _transformation.remove('camera');
    }

    if (gizmos != null) {
      if (_transformation['gizmos'] != null) {
        _transformation['gizmos']!.setFrom(gizmos);
      } 
      else {
        _transformation['gizmos'] = gizmos.clone();
      }
    } 
    else {
      _transformation.remove('gizmos');
    }
  }

	/// * Rotate camera around its direction axis passing by a given point by a given angle
	/// * [point] The point where the rotation axis is passing trough
	/// * [angle] Angle in radians
	/// * returns The computed transormation matix
  Map<String, Matrix4> zRotate(Vector3 point, double angle) {
    _rotationMatrix.makeRotationAxis(_rotationAxis, angle);
    _translationMatrix.makeTranslation(-point.x, -point.y, -point.z);

    _m4_1.makeTranslation(point.x, point.y, point.z);
    _m4_1.multiply(_rotationMatrix);
    _m4_1.multiply(_translationMatrix);

    _v3_1
        .setFromMatrixPosition(_gizmoMatrixState)
        .sub(point); //vector from rotation center to gizmos position
    _v3_2
        .setFrom(_v3_1)
        .applyAxisAngle(_rotationAxis, angle); //apply rotation
    _v3_2.sub(_v3_1);

    _m4_2.makeTranslation(_v3_2.x, _v3_2.y, _v3_2.z);

    setTransformationMatrices(_m4_1, _m4_2);
    return _transformation;
  }

  Raycaster getRaycaster() {
    return _raycaster;
  }

	/// * Unproject the cursor on the 3D object surface
	/// * [cursor] Cursor coordinates in NDC
	/// * [camera] Virtual camera
	/// * returns Vector3 The point of intersection with the model, if exist, null otherwise
  Vector3? unprojectOnObj(Vector2 cursor, Camera camera) {
    final raycaster = getRaycaster();
    raycaster.near = camera.near;
    raycaster.far = camera.far;
    raycaster.setFromCamera(cursor, camera);

    final intersect = raycaster.intersectObjects(scene!.children, true);

    for (int i = 0; i < intersect.length; i++) {
      if (intersect[i].object?.uuid != _gizmos.uuid &&
          intersect[i].face != null) {
        return intersect[i].point?.clone();
      }
    }

    return null;
  }

	/// * Unproject the cursor on the trackball surface
	/// * [camera] The virtual camera
	/// * [cursorX] Cursor horizontal coordinate on screen
	/// * [cursorY] Cursor vertical coordinate on screen
	/// * [tbRadius] The trackball radius
	/// * returns Vector3 The unprojected point on the trackball surface
  Vector3 unprojectOnTbSurface(Camera camera, double cursorX, double cursorY, double tbRadius) {
    if (camera is OrthographicCamera) {
      _v2_1.setFrom(getCursorPosition(cursorX, cursorY));
      _v3_1.setValues(_v2_1.x, _v2_1.y, 0);

      final x2 = math.pow(_v2_1.x, 2);
      final y2 = math.pow(_v2_1.y, 2);
      final r2 = math.pow(_tbRadius, 2);

      if (x2 + y2 <= r2 * 0.5) {
        //intersection with sphere
        _v3_1.setZ(math.sqrt(r2 - (x2 + y2)));
      } else {
        //intersection with hyperboloid
        _v3_1.setZ((r2 * 0.5) / (math.sqrt(x2 + y2)));
      }

      return _v3_1;
    } 
    else if (camera is PerspectiveCamera) {
      //unproject cursor on the near plane
      _v2_1.setFrom(getCursorNDC(cursorX, cursorY));

      _v3_1.setValues(_v2_1.x, _v2_1.y, -1);
      _v3_1.applyMatrix4(camera.projectionMatrixInverse);

      final rayDir = _v3_1.clone().normalize(); //unprojected ray direction
      final cameraGizmoDistance =
          camera.position.distanceTo(_gizmos.position);
      final radius2 = math.pow(tbRadius, 2);

      //	  camera
      //		|\
      //		| \
      //		|  \
      //	h	|	\
      //		| 	 \
      //		| 	  \
      //	_ _ | _ _ _\ _ _  near plane
      //			l

      final h = _v3_1.z;
      final l = math.sqrt(math.pow(_v3_1.x, 2) + math.pow(_v3_1.y, 2));

      if (l == 0) {
        //ray aligned with camera
        rayDir.setValues(_v3_1.x, _v3_1.y, tbRadius);
        return rayDir;
      }

      final m = h / l;
      final q = cameraGizmoDistance;

      /*
			 * calculate intersection point between unprojected ray and trackball surface
			 *|y = m * x + q
			 *|x^2 + y^2 = r^2
			 *
			 * (m^2 + 1) * x^2 + (2 * m * q) * x + q^2 - r^2 = 0
			 */
      num a = math.pow(m, 2) + 1;
      num b = 2 * m * q;
      num c = math.pow(q, 2) - radius2;
      num delta = math.pow(b, 2) - (4 * a * c);

      if (delta >= 0) {
        //intersection with sphere
        _v2_1.setX((-b - math.sqrt(delta)) / (2 * a));
        _v2_1.setY(m * _v2_1.x + q);

        final angle = MathUtils.rad2deg * _v2_1.angle();

        if (angle >= 45) {
          //if angle between intersection point and X' axis is >= 45°, return that point
          //otherwise, calculate intersection point with hyperboloid

          final rayLength = math.sqrt(math.pow(_v2_1.x, 2) +
              math.pow((cameraGizmoDistance - _v2_1.y), 2));
          rayDir.scale(rayLength);
          rayDir.z += cameraGizmoDistance;
          return rayDir;
        }
      }

      //intersection with hyperboloid
      /*
			 *|y = m * x + q
			 *|y = (1 / x) * (r^2 / 2)
			 *
			 * m * x^2 + q * x - r^2 / 2 = 0
			 */

      a = m;
      b = q;
      c = -radius2 * 0.5;
      delta = math.pow(b, 2) - (4 * a * c);
      _v2_1.setX((-b - math.sqrt(delta)) / (2 * a));
      _v2_1.setY(m * _v2_1.x + q);

      final rayLength = math.sqrt(math.pow(_v2_1.x, 2) +
          math.pow((cameraGizmoDistance - _v2_1.y), 2));

      rayDir.scale(rayLength);
      rayDir.z += cameraGizmoDistance;
      return rayDir;
    }

    return Vector3();
  }

	/// * Unproject the cursor on the plane passing through the center of the trackball orthogonal to the camera
	/// * [camera] The virtual camera
	/// * [cursorX] Cursor horizontal coordinate on screen
	/// * [cursorY] Cursor vertical coordinate on screen
	/// * [initialDistance] If initial distance between camera and gizmos should be used for calculations instead of current (Perspective only)
	/// * returns Vector3 The unprojected point on the trackball plane
  Vector3 unprojectOnTbPlane(Camera camera, double cursorX, double cursorY,[bool initialDistance = false]) {
    if (camera is OrthographicCamera) {
      _v2_1.setFrom(getCursorPosition(cursorX, cursorY));
      _v3_1.setValues(_v2_1.x, _v2_1.y, 0);

      return _v3_1.clone();
    } 
    else if (camera is PerspectiveCamera) {
      _v2_1.setFrom(getCursorNDC(cursorX, cursorY));

      //unproject cursor on the near plane
      _v3_1.setValues(_v2_1.x, _v2_1.y, -1);
      _v3_1.applyMatrix4(camera.projectionMatrixInverse);

      final rayDir = _v3_1.clone().normalize(); //unprojected ray direction

      //	  camera
      //		|\
      //		| \
      //		|  \
      //	h	|	\
      //		| 	 \
      //		| 	  \
      //	_ _ | _ _ _\ _ _  near plane
      //			l

      final h = _v3_1.z;
      final l = math.sqrt(math.pow(_v3_1.x, 2) + math.pow(_v3_1.y, 2));
      dynamic cameraGizmoDistance;

      if (initialDistance) {
        cameraGizmoDistance = _v3_1
            .setFromMatrixPosition(_cameraMatrixState0)
            .distanceTo(
                _v3_2.setFromMatrixPosition(_gizmoMatrixState0));
      } 
      else {
        cameraGizmoDistance = camera.position.distanceTo(_gizmos.position);
      }

      /*
			 * calculate intersection point between unprojected ray and the plane
			 *|y = mx + q
			 *|y = 0
			 *
			 * x = -q/m
			*/
      if (l == 0) {
        //ray aligned with camera
        rayDir.setValues(0, 0, 0);
        return rayDir;
      }

      final m = h / l;
      final q = cameraGizmoDistance;
      final x = -q / m;

      final rayLength = math.sqrt(math.pow(q, 2) + math.pow(x, 2));
      rayDir.scale(rayLength);
      rayDir.z = 0;
      return rayDir;
    }
    return Vector3();
  }

  
	/// Update camera and gizmos state
  void updateMatrixState() {
    //update camera and gizmos state
    _cameraMatrixState.setFrom(camera.matrix);
    _gizmoMatrixState.setFrom(_gizmos.matrix);

    if (camera is OrthographicCamera) {
      _cameraProjectionState.setFrom(camera.projectionMatrix);
      camera.updateProjectionMatrix();
      _zoomState = camera.zoom;
    } else if (camera is PerspectiveCamera) {
      _fovState = camera.fov;
    }
  }

	/// * Update the trackball FSA
	/// * [newState] New state of the FSA
	/// * [updateMatrices] If matriices state should be updated
  void updateTbState(newState, bool updateMatrices) {
    _state = newState;
    if (updateMatrices) {
      updateMatrixState();
    }
  }

  void update() {
    const eps = 0.000001;

    if (target.equals(_currentTarget) == false) {
      _gizmos.position.setFrom(target); //for correct radius calculation
      _tbRadius = calculateTbRadius(camera);
      makeGizmos(target, _tbRadius);
      _currentTarget.setFrom(target);
    }

    //check min/max parameters
    if (camera is OrthographicCamera) {
      //check zoom
      if (camera.zoom > maxZoom || camera.zoom < minZoom) {
        final newZoom =
            MathUtils.clamp(camera.zoom, minZoom, maxZoom);
        applyTransformMatrix(scale(newZoom / camera.zoom, _gizmos.position, true));
      }
    } else if (camera is PerspectiveCamera) {
      //check distance
      final distance = camera.position.distanceTo(_gizmos.position);

      if (distance > maxDistance + eps ||
          distance < minDistance - eps) {
        final newDistance =
            MathUtils.clamp(distance, minDistance, maxDistance);
        applyTransformMatrix(
            scale(newDistance / distance, _gizmos.position));
        updateMatrixState();
      }

      //check fov
      if (camera.fov < minFov || camera.fov > maxFov) {
        camera.fov =
            MathUtils.clamp(camera.fov, minFov, maxFov);
        camera.updateProjectionMatrix();
      }

      final oldRadius = _tbRadius;
      _tbRadius = calculateTbRadius(camera);

      if (oldRadius < _tbRadius - eps || oldRadius > _tbRadius + eps) {
        final scale = (_gizmos.scale.x +_gizmos.scale.y +_gizmos.scale.z) /3;
        final newRadius = _tbRadius / scale;
        final curve = EllipseCurve(0, 0, newRadius, newRadius);
        final points = curve.getPoints(_curvePts);
        final curveGeometry = BufferGeometry().setFromPoints(points);

        for (final gizmo in _gizmos.children) {
          // _gizmos.children[ gizmo ].geometry = curveGeometry;
          gizmo.geometry = curveGeometry;
        }
      }
    }

    camera.lookAt(_gizmos.position);
  }

  void setStateFromJSON(Map<String,dynamic> json) {
    // final state = JSON.parse( json );

    // if ( state.arcballState != null ) {

    // 	_cameraMatrixState.fromArray( state.arcballState.cameraMatrix.elements );
    // 	_cameraMatrixState.decompose( camera.position, camera.quaternion, camera.scale );

    // 	camera.up.copy( state.arcballState.cameraUp );
    // 	camera.near = state.arcballState.cameraNear;
    // 	camera.far = state.arcballState.cameraFar;

    // 	camera.zoom = state.arcballState.cameraZoom;

    // 	if ( camera is PerspectiveCamera ) {

    // 		camera.fov = state.arcballState.cameraFov;

    // 	}

    // 	_gizmoMatrixState.fromArray( state.arcballState.gizmoMatrix.elements );
    // 	_gizmoMatrixState.decompose( _gizmos.position, _gizmos.quaternion, _gizmos.scale );

    // 	camera.updateMatrix();
    // 	camera.updateProjectionMatrix();

    // 	_gizmos.updateMatrix();

    // 	_tbRadius = calculateTbRadius( camera );
    // 	final gizmoTmp = Matrix4().copy( _gizmoMatrixState0 );
    // 	makeGizmos( _gizmos.position, _tbRadius );
    // 	_gizmoMatrixState0.copy( gizmoTmp );

    // 	camera.lookAt( _gizmos.position );
    // 	updateTbState( State2.idle, false );

    // 	dispatchEvent( _changeEvent );

    // }
  }

  int cancelAnimationFrame(instance){
    return -1;
  }

  int requestAnimationFrame(Function callback) {
    return -1;
  }
}
