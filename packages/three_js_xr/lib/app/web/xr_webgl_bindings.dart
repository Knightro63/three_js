import 'dart:js_interop';

extension type XRSystem._(JSObject _) implements JSObject {
  @JS('navigator.xr')
  external XRSystem();
  @JS('navigator.xr.requestSession')
  external XRSession requestSession(String mode, Object options);
  @JS('navigator.xr.isSessionSupported')
  external bool isSessionSupported(String mode);
}

@JS('XRSession')
extension type XRSession._(JSObject _) implements JSObject {}

@JS('XRReferenceSpace')
extension type XRReferenceSpace._(JSObject _) implements JSObject {}

@JS('XRViewport')
extension type XRViewport._(JSObject _) implements JSObject {
  external int height;
  external int width;
}

@JS('XRWebGLLayer')
extension type XRWebGLLayer._(JSObject _) implements JSObject {
  external XRWebGLLayer(XRSession session, JSObject gl, JSFunction layerInit);
  external JSObject layerInit;
}

@JS('XRRigidTransform')
extension type XRRigidTransform._(JSObject _) implements JSObject {
  external JSObject position;
  external JSObject orientation;
  external List<double> matrix;
}

@JS('XRWebGLBinding')
extension type XRWebGLBinding._(JSObject _) implements JSObject {
  external XRWebGLBinding(XRSession session, JSObject gl);
  external XRSession session;
  external JSObject gl;
  external int textureWidth;
  external int textureHeight;
  external double fixedFoveation;
}

@JS('XRWebGLDepthInformation')
extension type XRWebGLDepthInformation._(JSObject _) implements JSObject {
  external JSObject texture;
  external double depthNear;
  external double depthFar;
}

@JS('XRRenderState')
extension type XRRenderState._(JSObject _) implements JSObject {
  external double depthNear;
  external double depthFar;
}

@JS('XRInputSource')
extension type XRInputSource._(JSObject _) implements JSObject {
  external JSObject targetRaySpace;
  external double depthFar;
  external JSObject hand;
  external JSObject handedness;
  external JSObject? gripSpace;
}

@JS('XRFrame')
extension type XRFrame._(JSObject _) implements JSObject {
  external JSObject getPose(,XRReferenceSpace space);
  external double depthFar;
  external JSObject getJointPose( ,XRReferenceSpace space);
  external JSObject session;
}