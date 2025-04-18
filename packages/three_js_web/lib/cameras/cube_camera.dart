@JS('THREE')
import '../core/index.dart';
import '../renderers/index.dart';
import 'perspective_camera.dart';
import 'dart:js_interop';

@JS('CubeCamera')
class CubeCamera extends Object3D {
  external WebGLCubeRenderTarget renderTarget;
  external PerspectiveCamera cameraPX;
  external PerspectiveCamera cameraNX;
  external PerspectiveCamera cameraPY;
  external PerspectiveCamera cameraNY;
  external PerspectiveCamera cameraPZ;
  external PerspectiveCamera cameraNZ;

  final double fov = 90;
  final double aspect = 1;

  external CubeCamera(double near, double far, WebGLCubeRenderTarget renderTarget);
  external void update(WebGLRenderer renderer, Object3D scene);

  @override
  external void dispose();
}
