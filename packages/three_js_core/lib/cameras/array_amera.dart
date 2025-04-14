import 'camera.dart';
import 'perspective_camera.dart';

/// [name] can be used in order to efficiently render a scene with a
/// predefined set of cameras. This is an important performance aspect for
/// rendering VR scenes.
/// 
/// An instance of [name] always has an array of sub cameras. It's mandatory
/// to define for each sub camera the `viewport` property which determines the
/// part of the viewport that is rendered with this camera.
class ArrayCamera extends PerspectiveCamera {
  List<Camera> cameras = [];

  /// [array]: An array of cameras.
  ArrayCamera(this.cameras) {
    type = 'ArrayCamera';
  }

  void dispose(){
    cameras.clear();
  }
}
