import 'package:vector_math/vector_math.dart';
import '../cameras/camera.dart';

extension Vector3Util on Vector3{
  Vector3 project(Camera camera) {
    // applyMatrix4(camera.matrixWorldInverse);
    // applyMatrix4(camera.projectionMatrix);
    return this;
  }

  Vector3 unproject(Camera camera) {
    // applyMatrix4(camera.projectionMatrixInverse);
    // applyMatrix4(camera.matrixWorld);
    return this;
  }
}