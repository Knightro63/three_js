import 'dart:js_interop';

@JS('navigator')
external JSObject get navigator; 

@JS('navigator.xr')
external XRSystem? get xrSystem;

@JS('XRSystem')
extension type XRSystem._(JSObject _) implements JSObject {
  external JSPromise<XRSession?> requestSession(String mode, JSAny? options);
  external JSPromise<JSAny?> isSessionSupported(String mode);
  external JSPromise<XRSession?> offerSession(String mode, JSAny? options);
  external void addEventListener(String name,JSAny? event);
}

@JS('XRSession')
extension type XRSession._(JSObject _) implements JSObject {
  external String? get visibilityState;
  external XRRenderState get renderState;
  external void updateRenderState(JSAny? state);
  external JSPromise<JSAny?> requestReferenceSpace(String type);
  external JSArray<XRInputSource>? inputSources;
  external String get environmentBlendMode;
  external void addEventListener(String name,JSAny? event);
  external void removeEventListener(String name,JSAny? event);
  external String depthUsage;
  external JSArray? enabledFeatures;
}

@JS('XRReferenceSpace')
extension type XRReferenceSpace._(JSObject _) implements JSObject {
  external XRReferenceSpace getOffsetReferenceSpace(XRRigidTransform originOffset);
}

@JS('XRViewport')
extension type XRViewport._(JSObject _) implements JSObject {
  external double get height;
  external double get width;
  external double get x;
  external double get y;
}

@JS('XRWebGLLayer')
extension type XRWebGLLayer._(JSObject _) implements JSObject {
  //external XRWebGLLayer(XRSession session, JSObject? context);
  external XRWebGLLayer(XRSession session, JSObject gl, JSAny? layerInit);
  external JSObject layerInit;

  external XRViewport getViewport(XRView view);
  external int get context;
  external JSObject? framebuffer;
  external int get framebufferWidth;
  external int get framebufferHeight;
  external bool get ignoreDepthValues;
  external bool get antialias;
  external double fixedFoveation;
}

@JS('XRRigidTransform')
extension type XRRigidTransform._(JSObject _) implements JSObject {
  external XRRigidTransform(JSAny? position, JSAny? rotation);
  external JSObject position;
  external JSObject orientation;
  external JSAny matrix;
}

@JS('XRWebGLBinding')
extension type XRWebGLBinding._(JSObject _) implements JSObject {
  external XRWebGLBinding(XRSession session, JSObject gl);
  external XRSession session;
  external JSObject gl;
  external int textureWidth;
  external int textureHeight;
  external double fixedFoveation;
  external XRWebGLDepthInformation? getDepthInformation(XRView view);
  external XRProjetionLayer createProjectionLayer(JSAny? map);
  external XRWebGLSubImage getViewSubImage(XRProjetionLayer layer, XRView view);
}

@JS('XRWebGLDepthInformation')
extension type XRWebGLDepthInformation._(JSObject _) implements JSObject {
  external JSObject texture;
  external double depthNear;
  external double depthFar;
  external bool isValid;
}
@JS('XRWebGLSubImage')
extension type XRWebGLSubImage._(JSObject _) implements JSObject {
  external XRViewport viewport;
  external JSObject? depthStencilTexture;
  external JSObject? colorTexture;
}
@JS('XRProjetionLayer')
extension type XRProjetionLayer._(JSObject _) implements JSObject {
  external int textureWidth;
  external int textureHeight;
  external double fixedFoveation;
  external bool get ignoreDepthValues;
}
@JS('XRLayer')
extension type XRLayer._(JSObject _) implements JSObject {

}
@JS('XRRenderState')
extension type XRRenderState._(JSObject _) implements JSObject {
  external double depthNear;
  external double depthFar;
  external XRLayer? layers;
}

@JS('XRHand')
extension type XRHand._(JSObject _) implements JSObject{
  external JSObject values();
}

@JS('XRInputSource')
extension type XRInputSource._(JSObject _) implements JSObject {
  external XRSpace targetRaySpace;
  external double depthFar;
  external XRHand? hand;
  external String? handedness;
  external XRSpace? gripSpace;
  external String? targetRayMode;
  external JSObject? gamepad;
  external JSObject? profiles;
}

@JS('XRSpace')
extension type XRSpace._(JSObject _) implements JSObject{}

@JS('XRJointSpace')
extension type XRJointSpace._(JSObject _) implements JSObject{}

@JS('XRPose')
extension type XRPose._(JSObject _) implements JSObject{
  external double? get angularVelocity;
  external double? get linearVelocity;
  external XRRigidTransform get transform;
}

@JS('XRJointPose')
extension type XRJointPose._(JSObject _) implements JSObject{
  external double get radius;
  external XRRigidTransform get transform;
}

@JS('XRView')
extension type XRView._(JSObject _) implements JSObject {
  external XRRigidTransform get transform;
  external JSObject projectionMatrix;
}

@JS('XRViewerPose')
extension type XRViewerPose._(JSObject _) implements JSObject {
  external JSArray<XRView> views;
}

@JS('XRFrame')
extension type XRFrame._(JSObject _) implements JSObject {
  external XRPose? getPose(XRSpace space, XRReferenceSpace? baseSpace);
  external double depthFar;
  external XRJointPose? getJointPose(XRJointSpace space,XRReferenceSpace? baseSpace);
  external XRSession session;
  external XRViewerPose getViewerPose(XRReferenceSpace? baseSpace);
  external JSObject? detectedPlanes;
}

@JS('XRHandedness')
extension type XRHandedness._(JSObject _) implements JSObject {

}