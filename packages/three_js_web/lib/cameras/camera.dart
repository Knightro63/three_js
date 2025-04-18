@JS('THREE')
import '../core/index.dart';
import 'dart:js_interop';
import '../math/index.dart';

@JS('Camera')
class Camera extends Object3D {
  external Matrix4 matrixWorldInverse;
  external Matrix4 projectionMatrix;
  external Matrix4 projectionMatrixInverse;

  external double fov;
  external double zoom;
  external double near;
  external double far;
  external double focus;
  external double aspect;
  external double filmGauge; // width of the film (default in millimeters)
  external double filmOffset; // horizontal film offset (same unit as gauge)

  //OrthographicCamera
  external double left;
  external double right;
  external double top;
  external double bottom;

  external Vector4? viewport;
  external int coordinateSystem;

  external Camera();

  Camera.fromJson(Map<String, dynamic>? json, Map<String, dynamic>? rootjson){
    Camera();
  }

  void updateProjectionMatrix() {
    throw(" Camera.updateProjectionMatrix not implimented.");
  }

  external Camera copy(Object3D source, [bool? recursive]);
  external Vector3 getWorldDirection(Vector3 target);
  external void updateMatrixWorld([bool force = false]);
  external void updateWorldMatrix(bool updateParents, bool updateChildren);
  external Camera clone([bool? recursive = true]);
}
