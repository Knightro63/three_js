@JS('THREE')
import 'camera.dart';
import 'perspective_camera.dart';
import 'dart:js_interop';

@JS('StereoCamera')
class StereoCamera {
  String type = 'StereoCamera';

  external double aspect;
  external double eyeSep;

  external PerspectiveCamera cameraL;
  external PerspectiveCamera cameraR;

  external StereoCamera();
  external void update(Camera camera);
  external void dispose();
}
