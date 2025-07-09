import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/app/web/xr_webgl_bindings.dart';
import 'package:three_js_xr/models/controller/motion_controllers_modle.dart';

class XRHandModel extends Object3D {
  Texture? envMap;
  Group controller;
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