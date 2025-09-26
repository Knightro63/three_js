import 'dart:io';

import 'package:three_js_core/core/event_dispatcher.dart';

XRSystem? xrSystem = XRSystem();

class XRSystem{
  Future<bool> isSupported(String type ) async{
    switch (type) {
      case 'immersive-vr' :
        if(Platform.isIOS || Platform.isAndroid || Platform.isMacOS){
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  void addListener(String name, dynamic event ){}

  Future<XRSession?> requestInit(String type, [dynamic options]) async{
    if(type == 'immersive-vr'){
      return XRSession();
    }
    return null;
  }
}

class XRSession with EventDispatcher{
  String? visibilityState;
  void cancelAnimationFrame([dynamic frame]){}

  void addListener(String name, Function event){
    addEventListener(name, event);
  }
  void removeListener(String name, Function event){
    removeEventListener(name, event);
  }

  void requestAnimationFrame(dynamic r){}
}

class XRHandedness{}
class XRFrame{
  XRSession? session;
  Map? detectedPlanesMap;
  XRPose? getPose(XRSpace space, XRReferenceSpace? baseSpace){
    return null;
  }
  XRJointPose? getJointPose(XRJointSpace space,XRReferenceSpace? baseSpace){
    return null;
  }
}
class XRJointSpace{}
class XRJointPose{
  double radius = 0;
  XRRigidTransform? transform;
}
class XRRenderState{
  double depthNear = 0;
  double depthFar = 0;
  XRLayer? layers;
}
class XRWebGLDepthInformation{
  dynamic texture;
  double depthNear = 0;
  double depthFar = 0;
  bool isValid = false;
}
class XRLayer{}
class XRSpace{}
class XRHand{}
class XRInputSource{
  String? handedness;
  Map? handMap;
  XRHand? hand;
  String? targetRayMode;
  dynamic gamepad;
  XRSpace? gripSpace;
  XRSpace? targetRaySpace;
  List? profilesList;
}
class XRPose{
  double? angularVelocity;
  double? linearVelocity;
  XRRigidTransform? transform;
}
class XRRigidTransform{
  XRRigidTransform(Map? position, Map? rotation);
  static XRRigidTransform init(Map? position, Map? rotation){
    return XRRigidTransform(position, rotation);
  }
  List<double> array = [];
}
class XRReferenceSpace{
  XRReferenceSpace? getOffsetReferenceSpace(XRRigidTransform originOffset){
    return null;
  }
}