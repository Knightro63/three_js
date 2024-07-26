part of three_js_transform_controls;

enum GizmoType{translate,rotate,scale,view}

class TransformControlsPlane extends Mesh {
  bool isTransformControlsPlane = true;

  Camera? camera;
  Object3D? object;
  bool enabled = true;
  String? axis;
  GizmoType mode = GizmoType.translate;
  String space = "world";
  double size = 1;
  bool dragging = false;
  bool showX = true;
  bool showY = true;
  bool showZ = true;

  // final worldPosition = new Vector3();
  // final worldPositionStart = new Vector3();
  // final worldQuaternion = new Quaternion();
  // final worldQuaternionStart = new Quaternion();
  // final cameraPosition = new Vector3();
  // final cameraQuaternion = new Quaternion();
  // final pointStart = new Vector3();
  // final pointEnd = new Vector3();
  // final rotationAxis = new Vector3();
  // num rotationAngle = 0;
  // final eye = new Vector3();

  Vector3 get eye {
    return controls.eye;
  }

  Vector3 get cameraPosition {
    return controls.cameraPosition;
  }

  Quaternion get cameraQuaternion {
    return controls.cameraQuaternion;
  }

  Vector3 get worldPosition {
    return controls.worldPosition;
  }

  num get rotationAngle {
    return controls.rotationAngle;
  }

  num? get rotationSnap {
    return controls.rotationSnap;
  }

  double? get translationSnap {
    return controls.translationSnap;
  }

  double? get scaleSnap {
    return controls.scaleSnap;
  }

  Vector3 get worldPositionStart {
    return controls.worldPositionStart;
  }

  Quaternion get worldQuaternion {
    return controls.worldQuaternion;
  }

  Quaternion get worldQuaternionStart {
    return controls.worldQuaternionStart;
  }

  Vector3 get pointStart {
    return controls.pointStart;
  }

  Vector3 get pointEnd {
    return controls.pointEnd;
  }

  Vector3 get rotationAxis {
    return controls.rotationAxis;
  }

  late TransformControls controls;

  TransformControlsPlane.create(super.geometry, super.material){
    type = "TransformControlsPlane";
  }

  factory TransformControlsPlane(controls) {
    final geometry = PlaneGeometry(100000, 100000, 2, 2);
    final material = MeshBasicMaterial.fromMap({
      "visible": false,
      "wireframe": true,
      "side": DoubleSide,
      "transparent": true,
      "opacity": 0.1,
      "toneMapped": false
    });

    final tcp = TransformControlsPlane.create(geometry, material);

    tcp.controls = controls;

    return tcp;
  }

  @override
  void updateMatrixWorld([bool force = false]) {
    String space = this.space;

    position.setFrom(worldPosition);

    if (mode == 'scale'){
      space = 'local'; // scale always oriented to local rotation
    }

    _v1.setFrom(_unitX).applyQuaternion(
        space == 'local' ? worldQuaternion : _identityQuaternion);
    _v2.setFrom(_unitY).applyQuaternion(
        space == 'local' ? worldQuaternion : _identityQuaternion);
    _v3.setFrom(_unitZ).applyQuaternion(
        space == 'local' ? worldQuaternion : _identityQuaternion);

    // Align the plane for current transform mode, axis and space.

    _alignVector.setFrom(_v2);

    switch (mode) {
      case GizmoType.translate:
      case GizmoType.scale:
        switch (axis) {
          case 'X':
            _alignVector.setFrom(eye).cross(_v1);
            _dirVector.setFrom(_v1).cross(_alignVector);
            break;
          case 'Y':
            _alignVector.setFrom(eye).cross(_v2);
            _dirVector.setFrom(_v2).cross(_alignVector);
            break;
          case 'Z':
            _alignVector.setFrom(eye).cross(_v3);
            _dirVector.setFrom(_v3).cross(_alignVector);
            break;
          case 'XY':
            _dirVector.setFrom(_v3);
            break;
          case 'YZ':
            _dirVector.setFrom(_v1);
            break;
          case 'XZ':
            _alignVector.setFrom(_v3);
            _dirVector.setFrom(_v2);
            break;
          case 'XYZ':
          case 'E':
            _dirVector.setValues(0, 0, 0);
            break;
        }

        break;
      case GizmoType.rotate:
      default:
        // special case for rotate
        _dirVector.setValues(0, 0, 0);
    }

    if (_dirVector.length == 0) {
      // If in rotate mode, make the plane parallel to camera
      quaternion.setFrom(cameraQuaternion);
    } else {
      _tempMatrix.lookAt(_tempVector.setValues(0, 0, 0), _dirVector, _alignVector);

      quaternion.setFromRotationMatrix(_tempMatrix);
    }

    super.updateMatrixWorld(force);
  }
}
