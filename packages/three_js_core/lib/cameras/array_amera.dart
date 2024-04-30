import 'camera.dart';
import 'perspective_camera.dart';

class ArrayCamera extends PerspectiveCamera {
  late List<Camera> cameras;

  ArrayCamera(List<Camera> array) {
    cameras = array;
    type = 'ArrayCamera';
  }
}
