part of three_renderers;

class WebXRManager with EventDispatcher {
  bool enabled = false;
  bool cameraAutoUpdate = true;
  final WebGLRenderer renderer;
  RenderingContext gl;
  bool isPresenting = false;
  Function? onXRSessionStart;
  Function? onXRSessionEnd;

  WebXRManager(this.renderer, this.gl) : super();
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