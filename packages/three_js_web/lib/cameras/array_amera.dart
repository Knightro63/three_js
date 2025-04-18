import 'perspective_camera.dart';
import 'dart:js_interop';

@JS('ArrayCamera')
class ArrayCamera extends PerspectiveCamera {
  external List cameras;
  external ArrayCamera(List cameras);
  external void dispose();
}
