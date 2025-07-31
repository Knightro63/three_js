import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/three_js_xr.dart';

class XRHandModel extends Object3D {
  Texture? envMap;
  WebXRController controller;
  MotionController? motionController;
  Mesh? mesh;
  XRInputSource? xrInputSource;

	XRHandModel(this.controller ):super();

  @override
	void updateMatrixWorld([bool force = false]) {
		super.updateMatrixWorld( force );
		motionController?.updateMesh();
	}
}