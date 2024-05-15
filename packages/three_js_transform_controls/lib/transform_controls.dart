part of three_js_transform_controls;

final _tempVector = Vector3.zero();
final _tempVector2 = Vector3.zero();
final _tempQuaternion = Quaternion.identity();
final _unit = {
  "X": Vector3(1, 0, 0),
  "Y": Vector3(0, 1, 0),
  "Z": Vector3(0, 0, 1)
};

final _mouseDownEvent = Event(type: 'mouseDown');
final _mouseUpEvent = Event(type: 'mouseUp', mode: null);
final _objectChangeEvent = Event(type: 'objectChange');

Pointer? _pointer0;

class TransformControls extends Object3D {
  bool isTransformControls = true;

  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;

  late TransformControlsGizmo _gizmo;
  late TransformControlsPlane _plane;

  late TransformControls scope;

  Camera? _camera;
  Camera? get camera => _camera;

  set camera(Camera? value) {
    if (value != _camera) {
      _camera = value;
      _plane.camera = value;
      _gizmo.camera = value;

      scope.dispatchEvent(Event(type: 'camera-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Object3D? _object;
  Object3D? get object => _object;

  set object(Object3D? value) {
    if (value != _object) {
      _object = value;
      _plane.object = value;
      _gizmo.object = value;

      scope.dispatchEvent(Event(type: 'object-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _enabled = true;
  bool get enabled => _enabled;

  set enabled(bool value) {
    if (value != _enabled) {
      _enabled = value;
      _plane.enabled = value;
      _gizmo.enabled = value;

      scope.dispatchEvent(Event(type: 'enabled-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  String? _axis;
  String? get axis => _axis;

  set axis(String? value) {
    if (value != _axis) {
      _axis = value;
      _plane.axis = value;
      _gizmo.axis = value;

      scope.dispatchEvent(Event(type: 'axis-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  String _mode = "translate";
  String get mode => _mode;

  set mode(String value) {
    if (value != _mode) {
      _mode = value;
      _plane.mode = value;
      _gizmo.mode = value;

      scope.dispatchEvent(Event(type: 'mode-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  double? _translationSnap;
  double? get translationSnap => _translationSnap;

  set translationSnap(double? value) {
    if (value != _translationSnap) {
      _translationSnap = value;

      scope.dispatchEvent(
          Event(type: 'translationSnap-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  double? _rotationSnap;
  double? get rotationSnap => _rotationSnap;

  set rotationSnap(double? value) {
    if (value != _rotationSnap) {
      _rotationSnap = value;

      scope.dispatchEvent(
          Event(type: 'rotationSnap-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  double? _scaleSnap;
  double? get scaleSnap => _scaleSnap;

  set scaleSnap(double? value) {
    if (value != _scaleSnap) {
      _scaleSnap = value;

      scope.dispatchEvent(Event(type: 'scaleSnap-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  String _space = "world";
  String get space => _space;

  set space(String value) {
    if (value != _space) {
      _space = value;
      _plane.space = value;
      _gizmo.space = value;

      scope.dispatchEvent(Event(type: 'space-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  int _size = 1;
  int get size => _size;

  set size(int value) {
    if (value != _size) {
      _size = value;
      _plane.size = value;
      _gizmo.size = value;

      scope.dispatchEvent(Event(type: 'size-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _dragging = false;
  bool get dragging => _dragging;

  set dragging(bool value) {
    
    if (value != _dragging) {
      _dragging = value;
      _plane.dragging = value;
      _gizmo.dragging = value;

      scope.dispatchEvent(Event(type: 'dragging-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _showX = true;
  bool get showX => _showX;

  set showX(bool value) {
    if (value != _showX) {
      _showX = value;
      _plane.showX = value;
      _gizmo.showX = value;

      scope.dispatchEvent(Event(type: 'showX-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _showY = true;
  bool get showY => _showY;

  set showY(bool value) {
    if (value != _showY) {
      _showY = value;
      _plane.showY = value;
      _gizmo.showY = value;

      scope.dispatchEvent(Event(type: 'showY-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _showZ = true;
  bool get showZ => _showZ;

  set showZ(bool value) {
    if (value != _showZ) {
      _showZ = value;
      _plane.showZ = value;
      _gizmo.showZ = value;

      scope.dispatchEvent(Event(type: 'showZ-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  // Reusable utility variables

  // final worldPosition = Vector3.zero();
  // final worldPositionStart = Vector3.zero();
  // final worldQuaternion = Quaternion.identity();
  // final worldQuaternionStart = Quaternion.identity();
  // final cameraPosition = Vector3.zero();
  // final cameraQuaternion = Quaternion.identity();
  // final pointStart = Vector3.zero();
  // final pointEnd = Vector3.zero();
  // final rotationAxis = Vector3.zero();
  // final rotationAngle = 0;
  // final eye = Vector3.zero();

  Vector3 _worldPosition = Vector3.zero();
  Vector3 get worldPosition => _worldPosition;

  set worldPosition(Vector3 value) {
    if (value != _worldPosition) {
      _worldPosition = value;

      scope.dispatchEvent(
          Event(type: 'worldPosition-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _worldPositionStart = Vector3.zero();
  Vector3 get worldPositionStart => _worldPositionStart;

  set worldPositionStart(Vector3 value) {
    if (value != _worldPositionStart) {
      _worldPositionStart = value;

      scope.dispatchEvent(
          Event(type: 'worldPositionStart-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Quaternion _worldQuaternion = Quaternion.identity();
  Quaternion get worldQuaternion => _worldQuaternion;

  set worldQuaternion(Quaternion value) {
    if (value != _worldQuaternion) {
      _worldQuaternion = value;

      scope.dispatchEvent(
          Event(type: 'worldQuaternion-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Quaternion _worldQuaternionStart = Quaternion.identity();
  Quaternion get worldQuaternionStart => _worldQuaternionStart;

  set worldQuaternionStart(Quaternion value) {
    if (value != _worldQuaternionStart) {
      _worldQuaternionStart = value;

      scope.dispatchEvent(
          Event(type: 'worldQuaternionStart-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _cameraPosition = Vector3.zero();
  Vector3 get cameraPosition => _cameraPosition;

  set cameraPosition(Vector3 value) {
    if (value != _cameraPosition) {
      _cameraPosition = value;

      scope.dispatchEvent(
          Event(type: 'cameraPosition-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Quaternion _cameraQuaternion = Quaternion.identity();
  Quaternion get cameraQuaternion => _cameraQuaternion;

  set cameraQuaternion(Quaternion value) {
    if (value != _cameraQuaternion) {
      _cameraQuaternion = value;

      scope.dispatchEvent(
          Event(type: 'cameraQuaternion-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _pointStart = Vector3.zero();
  Vector3 get pointStart => _pointStart;

  set pointStart(Vector3 value) {
    if (value != _pointStart) {
      _pointStart = value;

      scope
          .dispatchEvent(Event(type: 'pointStart-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _pointEnd = Vector3.zero();
  Vector3 get pointEnd => _pointEnd;

  set pointEnd(Vector3 value) {
    if (value != _pointEnd) {
      _pointEnd = value;

      scope.dispatchEvent(Event(type: 'pointEnd-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _rotationAxis = Vector3.zero();
  Vector3 get rotationAxis => _rotationAxis;

  set rotationAxis(Vector3 value) {
    if (value != _rotationAxis) {
      _rotationAxis = value;

      scope.dispatchEvent(
          Event(type: 'rotationAxis-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  double _rotationAngle = 0;
  double get rotationAngle => _rotationAngle;

  set rotationAngle(double value) {
    if (value != _rotationAngle) {
      _rotationAngle = value;

      scope.dispatchEvent(
          Event(type: 'rotationAngle-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _eye = Vector3.zero();
  Vector3 get eye => _eye;

  set eye(Vector3 value) {
    if (value != _eye) {
      _eye = value;

      scope.dispatchEvent(Event(type: 'eye-changed', value: value));
      scope.dispatchEvent(_changeEvent);
    }
  }

  final _offset = Vector3.zero();
  final _startNorm = Vector3.zero();
  final _endNorm = Vector3.zero();
  final _cameraScale = Vector3.zero();

  final _parentPosition = Vector3.zero();
  final _parentQuaternion = Quaternion.identity();
  final _parentQuaternionInv = Quaternion.identity();
  final _parentScale = Vector3.zero();

  final _worldScaleStart = Vector3.zero();
  final _worldQuaternionInv = Quaternion.identity();
  final _worldScale = Vector3.zero();

  final _positionStart = Vector3.zero();
  final _quaternionStart = Quaternion.identity();
  final _scaleStart = Vector3.zero();

  TransformControls(Camera? camera, this.listenableKey) : super() {
    scope = this;
    visible = false;
    // this.domElement.style.touchAction = 'none'; // disable touch scroll

    _gizmo = TransformControlsGizmo(this);
    _gizmo.name = "TransformControlsGizmo";

    _plane = TransformControlsPlane(this);
    _plane.name = "TransformControlsPlane";

    this.camera = camera;

    add(_gizmo);
    add(_plane);
    
    domElement.addEventListener(PeripheralType.pointerdown, _onPointerDown, false);
    domElement.addEventListener(PeripheralType.pointerHover, _onPointerHover, false);
    domElement.addEventListener(PeripheralType.pointerup, _onPointerUp, false);
  }

  // updateMatrixWorld  updates key transformation variables
  @override
  void updateMatrixWorld([bool force = false]) {
    if (object != null) {
      object?.updateMatrixWorld(force);

      if (object?.parent == null) {
        console.warning('TransformControls: The attached 3D object must be a part of the scene graph.');
      } 
      else {
        object?.parent?.matrixWorld.decompose(_parentPosition, _parentQuaternion, _parentScale);
      }

      object?.matrixWorld.decompose(worldPosition, worldQuaternion, _worldScale);

      _parentQuaternionInv.setFrom(_parentQuaternion).invert();
      _worldQuaternionInv.setFrom(worldQuaternion).invert();
    }

    camera?.updateMatrixWorld(force);

    camera?.matrixWorld
        .decompose(cameraPosition, cameraQuaternion, _cameraScale);

    eye.setFrom(cameraPosition).sub(worldPosition).normalize();

    super.updateMatrixWorld(force);
  }

  void pointerHover(Pointer pointer) {
    if (object == null || dragging == true) return;

    _raycaster.setFromCamera(Vector2(pointer.x, pointer.y), camera!);

    final intersect = intersectObjectWithRay(_gizmo.picker[mode], _raycaster, false);

    if (intersect != null) {
      axis = intersect.object?.name;
    } 
    else {
      axis = null;
    }
  }

  void pointerDown(Pointer pointer) {
    _pointer0 = pointer;
    if (object == null || dragging == true || pointer.button != 0){
      return;
    }
    
    if (axis != null) {
      _raycaster.setFromCamera(Vector2(pointer.x, pointer.y), camera!);

      final planeIntersect = intersectObjectWithRay(_plane, _raycaster, true);

      if (planeIntersect != null) {
        object?.updateMatrixWorld(false);
        object?.parent?.updateMatrixWorld(false);

        _positionStart.setFrom(object!.position);
        _quaternionStart.setFrom(object!.quaternion);
        _scaleStart.setFrom(object!.scale);

        object?.matrixWorld.decompose(worldPositionStart,worldQuaternionStart, _worldScaleStart);

        pointStart.setFrom(planeIntersect.point!).sub(worldPositionStart);
      }

      dragging = true;
      _mouseDownEvent.mode = mode;
      dispatchEvent(_mouseDownEvent);
    }
  }

  void pointerMove(Pointer pointer) {
    if (pointer.x == _pointer0?.x &&
        pointer.y == _pointer0?.y &&
        pointer.button == _pointer0?.button) {
      return;
    }
    _pointer0 = pointer;

    final axis = this.axis;
    final mode = this.mode;
    final object = this.object;
    String space = this.space;

    if (mode == 'scale') {
      space = 'local';
    } 
    else if (axis == 'E' || axis == 'XYZE' || axis == 'XYZ') {
      space = 'world';
    }

    if (object == null ||
        axis == null ||
        dragging == false ||
        pointer.button != 0) return;

    _raycaster.setFromCamera(Vector2(pointer.x, pointer.y), camera!);

    final planeIntersect = intersectObjectWithRay(_plane, _raycaster, true);

    if (planeIntersect == null) return;

    pointEnd.setFrom(planeIntersect.point!).sub(worldPositionStart);

    if (mode == 'translate') {
      // Apply translate

      _offset.setFrom(pointEnd).sub(pointStart);

      if (space == 'local' && axis != 'XYZ') {
        _offset.applyQuaternion(_worldQuaternionInv);
      }

      if (!axis.contains('X')) _offset.x = 0;
      if (!axis.contains('Y')) _offset.y = 0;
      if (!axis.contains('Z')) _offset.z = 0;

      if (space == 'local' && axis != 'XYZ') {
        _offset.applyQuaternion(_quaternionStart).divide(_parentScale);
      } 
      else {
        _offset.applyQuaternion(_parentQuaternionInv).divide(_parentScale);
      }

      object.position.setFrom(_offset).add(_positionStart);

      // Apply translation snap

      if (translationSnap != null) {
        if (space == 'local') {
          object.position.applyQuaternion(
              _tempQuaternion.setFrom(_quaternionStart).invert());

          if (axis.contains('X')) {
            object.position.x = (object.position.x / translationSnap!).round() * translationSnap!;
          }

          if (axis.contains('Y')) {
            object.position.y = (object.position.y / translationSnap!).round() * translationSnap!;
          }

          if (axis.contains('Z')) {
            object.position.z = (object.position.z / translationSnap!).round() * translationSnap!;
          }

          object.position.applyQuaternion(_quaternionStart);
        }

        if (space == 'world') {
          if (object.parent != null) {
            //final _vec = _tempVector.setFromMatrixPosition(object.parent?.matrixWorld);
            object.position.add(_tempVector.setFromMatrixPosition(object.parent?.matrixWorld));
          }

          if (axis.contains('X')) {
            object.position.x = (object.position.x / translationSnap!).round() * translationSnap!;
          }

          if (axis.contains('Y')) {
            object.position.y = (object.position.y / translationSnap!).round() * translationSnap!;
          }

          if (axis.contains('Z')) {
            object.position.z = (object.position.z / translationSnap!).round() * translationSnap!;
          }

          if (object.parent != null) {
            object.position.sub(
                _tempVector.setFromMatrixPosition(object.parent?.matrixWorld));
          }
        }
      }
    } 
    else if (mode == 'scale') {
      if (axis.contains('XYZ')) {
        double d = pointEnd.length / pointStart.length;

        if (pointEnd.dot(pointStart) < 0){ 
          d *= -1;
        }

        _tempVector2.setValues(d, d, d);
      } 
      else {
        _tempVector.setFrom(pointStart);
        _tempVector2.setFrom(pointEnd);

        _tempVector.applyQuaternion(_worldQuaternionInv);
        _tempVector2.applyQuaternion(_worldQuaternionInv);

        _tempVector2.divide(_tempVector);

        if (axis.contains('X')) {
          _tempVector2.x = 1;
        }

        if (axis.contains('Y')) {
          _tempVector2.y = 1;
        }

        if (axis.contains('Z')) {
          _tempVector2.z = 1;
        }
      }

      // Apply scale

      object.scale.setFrom(_scaleStart).multiply(_tempVector2);

      if (scaleSnap != null) {
        if (axis.contains('X')) {
          double x_ = (object.scale.x / scaleSnap!).round() * scaleSnap!;
          object.scale.x = x_ != 0 ? x_ : scaleSnap!;
        }

        if (axis.contains('Y')) {
          double y_ = (object.scale.y / scaleSnap!).round() * scaleSnap!;
          object.scale.y = y_ != 0 ? y_ : scaleSnap!;
        }

        if (axis.contains('Z')) {
          double z_ = (object.scale.z / scaleSnap!).round() * scaleSnap!;
          object.scale.z = z_ != 0 ? z_ : scaleSnap!;
        }
      }
    } 
    else if (mode == 'rotate') {
      _offset.setFrom(pointEnd).sub(pointStart);

      final rotationSpeed = 20 / worldPosition.distanceTo(
              _tempVector.setFromMatrixPosition(camera?.matrixWorld));

      if (axis == 'E') {
        rotationAxis.setFrom(eye);
        rotationAngle = pointEnd.angleTo(pointStart);

        _startNorm.setFrom(pointStart).normalize();
        _endNorm.setFrom(pointEnd).normalize();

        rotationAngle *=
            (_endNorm.cross(_startNorm).dot(eye) < 0 ? 1 : -1);
      } 
      else if (axis == 'XYZE') {
        rotationAxis.setFrom(_offset).cross(eye).normalize();
        rotationAngle = _offset.dot(_tempVector.setFrom(rotationAxis).cross(eye)) * rotationSpeed;
      } 
      else if (axis == 'X' || axis == 'Y' || axis == 'Z') {
        rotationAxis.setFrom(_unit[axis]!);

        _tempVector.setFrom(_unit[axis]!);

        if (space == 'local') {
          _tempVector.applyQuaternion(worldQuaternion);
        }

        rotationAngle = _offset.dot(_tempVector.cross(eye).normalize()) * rotationSpeed;
      }

      // Apply rotation snap

      if (rotationSnap != null){
        rotationAngle = (rotationAngle / rotationSnap!).roundToDouble() * rotationSnap!;
      }

      // Apply rotate
      if (space == 'local' && axis != 'E' && axis != 'XYZE') {
        object.quaternion.setFrom(_quaternionStart);
        object.quaternion
            .multiply(_tempQuaternion.setFromAxisAngle(rotationAxis, rotationAngle))
            .normalize();
      } else {
        rotationAxis.applyQuaternion(_parentQuaternionInv);
        object.quaternion.setFrom(_tempQuaternion.setFromAxisAngle(
            rotationAxis, rotationAngle));
        object.quaternion.multiply(_quaternionStart).normalize();
      }
    }

    dispatchEvent(_changeEvent);
    dispatchEvent(_objectChangeEvent);
  }

  void pointerUp(Pointer pointer) {
    if (pointer.button != 0) return;

    if (dragging && (axis != null)) {
      _mouseUpEvent.mode = mode;
      dispatchEvent(_mouseUpEvent);
    }

    dragging = false;
    axis = null;
  }

  @override
  void dispose() {
    domElement.removeEventListener(PeripheralType.pointerdown, _onPointerDown);
    domElement.removeEventListener(PeripheralType.pointerHover, _onPointerHover);
    domElement.removeEventListener(PeripheralType.pointermove, _onPointerMove);
    domElement.removeEventListener(PeripheralType.pointerup, _onPointerUp);

    traverse((child) {
      child.geometry?.dispose();
      child.material?.dispose();
    });
  }

  // Set current object
  @override
  TransformControls attach(Object3D? object) {
    this.object = object;
    visible = true;

    return this;
  }

  // Detatch from object
  TransformControls detach() {
    object = null;
    visible = false;
    axis = null;

    return this;
  }

  Raycaster getRaycaster() {
    return _raycaster;
  }

  String getMode() {
    return mode;
  }

  void setMode(mode) {
    this.mode = mode;
  }

  void setTranslationSnap(translationSnap) {
    this.translationSnap = translationSnap;
  }

  void setRotationSnap(rotationSnap) {
    this.rotationSnap = rotationSnap;
  }

  void setScaleSnap(scaleSnap) {
    this.scaleSnap = scaleSnap;
  }

  void setSize(size) {
    this.size = size;
  }

  void setSpace(space) {
    this.space = space;
  }
  @Deprecated("TransformControls: update function has no more functionality.")
  void update() {}

  // mouse / touch event handlers
  Pointer _getPointer(event) {
    return getPointer(event);
  }

  void _onPointerDown(event) {
    return onPointerDown(event);
  }

  void _onPointerHover(event) {
    return onPointerHover(event);
  }

  void _onPointerMove(event) {
    return onPointerMove(event);
  }

  void _onPointerUp(event) {
    return onPointerUp(event);
  }

  Pointer getPointer(WebPointerEvent event) {
    final RenderBox renderBox = listenableKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final rect = size;
    int left = 0;
    int top = 0;

    final x_ = (event.clientX - left) / rect.width * 2 - 1;
    final y_ = -(event.clientY - top) / rect.height * 2 + 1;
    final button = event.button;

    return Pointer(x_, y_, button);
  }

  void onPointerHover(event) {
    if (!enabled) return;

    switch (event.pointerType) {
      case 'mouse':
      case 'pen':
        pointerHover(_getPointer(event));
        break;
    }
  }

  void onPointerDown(event) {
    if (!enabled) return;
    // this.domElement.setPointerCapture( event.pointerId );

    domElement.addEventListener(PeripheralType.pointermove, _onPointerMove);

    pointerHover(_getPointer(event));
    pointerDown(_getPointer(event));
  }

  void onPointerMove(event) {
    if (!enabled) return;

    pointerMove(_getPointer(event));
  }

  void onPointerUp(event) {
    if (!enabled) return;

    // this.domElement.releasePointerCapture( event.pointerId );

    domElement.removeEventListener(PeripheralType.pointermove, _onPointerMove);

    pointerUp(_getPointer(event));
  }

  Intersection? intersectObjectWithRay(Mesh object, Raycaster raycaster, bool includeInvisible) {
    final allIntersections = raycaster.intersectObject(object, true, null);

    for (int i = 0; i < allIntersections.length; i++) {
      if (allIntersections[i].object!.visible || includeInvisible) {
        return allIntersections[i];
      }
    }

    return null;
  }
}

class Pointer {
  late double x;
  late double y;
  late int button;
  Pointer(this.x, this.y, this.button);

  Map<String,dynamic> toJSON() {
    return {"x": x, "y": y, "button": button};
  }
}
