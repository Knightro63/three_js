import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter/material.dart' hide Matrix4;

/// This class can be used to provide a drag'n'drop interaction.
class DragControls with EventDispatcher {
  late DragControls scope;

  bool enabled = true;
  bool transformGroup = false;
  final List<Intersection> _intersections = [];
  Object3D? _selected;
  Object3D? _hovered;

  late Camera camera;
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get _domElement => listenableKey.currentState!;
  late List<Object3D> objects;
  List<Object3D> get _objects => objects;
  Camera get _camera => camera;

  final _raycaster = Raycaster();
  final _plane = Plane();
  final _pointer = Vector2.zero();
  final _offset = Vector3.zero();
  final _intersection = Vector3.zero();
  final _worldPosition = Vector3.zero();
  final _inverseMatrix = Matrix4.identity();

  /// [objects] - An array of draggable 3D objects.
  /// 
  /// [camera] - The camera of the rendered scene.
  /// 
  /// [listenableKey] - The element used for event listeners.
  DragControls(this.objects, this.camera, this.listenableKey):super() {
    scope = this;
    activate();
  }

  /// Adds the event listeners of the controls.
  void activate() {
    _domElement.addEventListener(PeripheralType.pointermove, onPointerMove);
    _domElement.addEventListener(PeripheralType.pointerdown, onPointerDown);
    _domElement.addEventListener(PeripheralType.pointerup, onPointerCancel);
    _domElement.addEventListener(PeripheralType.pointerleave, onPointerCancel);
  }

  /// Removes the event listeners of the controls.
  void deactivate() {
    _domElement.removeEventListener(PeripheralType.pointermove, onPointerMove);
    _domElement.removeEventListener(PeripheralType.pointerdown, onPointerDown);
    _domElement.removeEventListener(PeripheralType.pointerup, onPointerCancel);
    _domElement.removeEventListener(PeripheralType.pointerleave, onPointerCancel);

    // _domElement.style.cursor = '';
  }

  /// Should be called if the controls is no longer required.
  void dispose() {
    clearListeners();
  }

  get getObjects => _objects;
  get getRaycaster => _raycaster;

  void onPointerMove(event) {
    if (scope.enabled == false) return;

    updatePointer(event);

    _raycaster.setFromCamera(_pointer, _camera);

    if (_selected != null) {
      if (_raycaster.ray.intersectPlane(_plane, _intersection) != null) {
        _selected!.position.setFrom(_intersection.sub(_offset).applyMatrix4(_inverseMatrix));
      }

      scope.dispatchEvent(Event(type: 'drag', object: _selected));

      return;
    }

    // hover support

    if (event.pointerType == 'mouse' || event.pointerType == 'pen') {
      _intersections.length = 0;

      _raycaster.setFromCamera(_pointer, _camera);
      _raycaster.intersectObjects(_objects, true, _intersections);

      if (_intersections.isNotEmpty) {
        final object = _intersections[0].object;

        _plane.setFromNormalAndCoplanarPoint(
            _camera.getWorldDirection(_plane.normal),
            _worldPosition.setFromMatrixPosition(object?.matrixWorld));

        if (_hovered != object && _hovered != null) {
          scope.dispatchEvent(Event(type: 'hoveroff', object: _hovered));
          _hovered = null;
        }

        if (_hovered != object) {
          scope.dispatchEvent(Event(type: 'hoveron', object: object));
          _hovered = object;
        }
      } 
      else {
        if (_hovered != null) {
          scope.dispatchEvent(Event(type: 'hoveroff', object: _hovered));
          _hovered = null;
        }
      }
    }
  }

  void onPointerDown(event) {
    if (!scope.enabled){
      return;
    }

    updatePointer(event);

    _intersections.length = 0;

    _raycaster.setFromCamera(_pointer, _camera);
    _raycaster.intersectObjects(_objects, true, _intersections);

    if (_intersections.isNotEmpty) {
      _selected = (scope.transformGroup == true)
          ? _objects[0]
          : _intersections[0].object;

      _plane.setFromNormalAndCoplanarPoint(
          _camera.getWorldDirection(_plane.normal),
          _worldPosition.setFromMatrixPosition(_selected!.matrixWorld)
        );

      if (_raycaster.ray.intersectPlane(_plane, _intersection) != null) {
        _inverseMatrix.setFrom(_selected!.parent!.matrixWorld).invert();
        _offset.setFrom(_intersection)
            .sub(_worldPosition.setFromMatrixPosition(_selected!.matrixWorld));
      }

      scope.dispatchEvent(Event(type: 'dragstart', object: _selected));
    }
  }

  void onPointerCancel() {
    if (!scope.enabled){ 
      return;
    }
    if(_selected != null) {
      scope.dispatchEvent(Event(type: 'dragend', object: _selected));
      _selected = null;
    }
  }

  void updatePointer(event) {
    final box = listenableKey.currentContext?.findRenderObject() as RenderBox;
    final size = box.size;
    final local = box.globalToLocal(const Offset(0, 0));

    _pointer.x = (event.clientX - local.dx) / size.width * 2 - 1;
    _pointer.y = -(event.clientY - local.dy) / size.height * 2 + 1;
  }
}
