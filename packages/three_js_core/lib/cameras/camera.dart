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

class Camera extends Object3D {
  Matrix4 matrixWorldInverse = Matrix4.identity();

  Matrix4 projectionMatrix = Matrix4.identity();
  Matrix4 projectionMatrixInverse = Matrix4.identity();

  late double fov;
  double zoom = 1.0;
  late double near;
  late double far;
  double focus = 10;
  late double aspect;
  double filmGauge = 35; // width of the film (default in millimeters)
  double filmOffset = 0; // horizontal film offset (same unit as gauge)

  //OrthographicCamera
  late double left;
  late double right;
  late double top;
  late double bottom;

  CameraView? view;//Map<String, dynamic>? view;

  late Vector4 viewport;

  Camera():super(){
    type = "Camera";
  }

  Camera.fromJson(Map<String,dynamic> json, Map<String,dynamic> rootJson):super.fromJson(json, rootJson){
    type = "Camera";
  }

  void updateProjectionMatrix() {
    throw(" Camera.updateProjectionMatrix not implimented.");
  }

  @override
  Camera copy(Object3D source, [bool? recursive]) {
    super.copy(source, recursive);
    Camera source1 = source as Camera;

    matrixWorldInverse.setFrom(source1.matrixWorldInverse);
    projectionMatrix.setFrom(source1.projectionMatrix);
    projectionMatrixInverse.setFrom(source1.projectionMatrixInverse);

    return this;
  }

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

  @override
  Camera clone([bool? recursive = true]) {
    return Camera()..copy(this);
  }
}
