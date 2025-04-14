import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';

class CameraView{
  CameraView({
    this.enabled = true,
    this.fullWidth = 1,
    this.fullHeight = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.width = 1,
    this.height = 1,
  });

  bool enabled;
  double fullWidth;
  double fullHeight;
  double offsetX;
  double offsetY;
  double width;
  double height;

  Map<String,dynamic> get toMap => {
    'enabled': enabled,
    'fullWidth': fullWidth,
    'fullHeight': fullHeight,
    'offsetX': offsetX,
    'offsetY':offsetY,
    'width':width,
    'height':height
  };
}

/// Abstract base class for cameras. This class should always be inherited
/// when you build a new camera.
class Camera extends Object3D {
  Matrix4 matrixWorldInverse = Matrix4.identity();

  Matrix4 projectionMatrix = Matrix4.identity();
  Matrix4 projectionMatrixInverse = Matrix4.identity();

  double fov = 50;
  double zoom = 1.0;
  double near = 0.1;
  double far = 2000;
  double focus = 10;
  double aspect = 1;
  double filmGauge = 35; // width of the film (default in millimeters)
  double filmOffset = 0; // horizontal film offset (same unit as gauge)

  //OrthographicCamera
  double left = -1;
  double right = 1;
  double top = 1;
  double bottom = -1;

  CameraView? view;//Map<String, dynamic>? view;
  Vector4? viewport;
  int coordinateSystem = 2000;

  /// Creates a new [name]. Note that this class is not intended to be called
  /// directly; you probably want a [PerspectiveCamera] or
  /// [OrthographicCamera] instead.
  Camera():super(){
    type = "Camera";
  }

  Camera.fromJson(Map<String,dynamic> json, Map<String,dynamic> rootJson):super.fromJson(json, rootJson){
    type = "Camera";
  }

  void updateProjectionMatrix() {
    throw(" Camera.updateProjectionMatrix not implimented.");
  }

  /// Copy the properties from the source camera into this one.
  @override
  Camera copy(Object3D source, [bool? recursive]) {
    super.copy(source, recursive);
    Camera source1 = source as Camera;

    matrixWorldInverse.setFrom(source1.matrixWorldInverse);
    projectionMatrix.setFrom(source1.projectionMatrix);
    projectionMatrixInverse.setFrom(source1.projectionMatrixInverse);

    return this;
  }

  /// [target] — the result will be copied into this Vector3.
  ///
  /// 
  /// Returns a [Vector3] representing the world space direction in which
  /// the camera is looking. (Note: A camera looks down its local, negative
  /// z-axis).
  @override
  Vector3 getWorldDirection(Vector3 target) {
    updateWorldMatrix(true, false);
    final e = matrixWorld.storage;
    target.setValues(-e[8], -e[9], -e[10]);
    target.normalize();
    return target;
  }

  @override
  void updateMatrixWorld([bool force = false]) {
    super.updateMatrixWorld(force);
    matrixWorldInverse.setFrom(matrixWorld);
    matrixWorldInverse.invert();
  }

  @override
  void updateWorldMatrix(bool updateParents, bool updateChildren) {
    super.updateWorldMatrix(updateParents, updateChildren);
    matrixWorldInverse.setFrom(matrixWorld);
    matrixWorldInverse.invert();
  }

  /// Return a new camera with the same properties as this one.
  @override
  Camera clone([bool? recursive = true]) {
    return Camera()..copy(this);
  }
}
