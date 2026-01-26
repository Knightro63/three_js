import 'package:three_js_core/three_js_core.dart';

class XRManager with EventDispatcher {
  bool enabled = false;
  bool cameraAutoUpdate = true;
  final Renderer renderer;
  dynamic gl;
  bool isPresenting = false;
  Function? onXRSessionStart;
  Function? onXRSessionEnd;

  XRManager(this.renderer, this.gl) : super();
  void init(){}

  void setAnimationLoop ( callback ) {
    throw("Not Implimented yet!");
  }
  void updateCamera(Camera camera ) {
    throw("Not Implimented yet!");
  }
  ArrayCamera getCamera() {
    throw("Not Implimented yet!");
  }
  bool hasDepthSensing () {
    return false;
  }
  Mesh? getDepthSensingMesh() {
    return null;
  }
  String? getEnvironmentBlendMode () {
    return null;
  }
}