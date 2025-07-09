import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/app/web/xr_webgl_bindings.dart';
import 'package:three_js_xr/models/hand/xr_hand_mesh_modle.dart';
import 'package:three_js_xr/models/hand/xr_hand_modle.dart';
import 'package:three_js_xr/models/hand/xr_hand_primitive_modle.dart';
import 'package:three_js_advanced_loaders/three_js_advanced_loaders.dart';

class XRHandModelFactory {
  GLTFLoader? gltfLoader;
  String? path;
  Function? onLoad;

	XRHandModelFactory([this.gltfLoader, this.onLoad ]);

	XRHandModelFactory setPath(String path ) {
		this.path = path;
		return this;
	}

	XRHandModel createHandModel(Group controller, profile ) {
		final handModel = XRHandModel( controller );

		controller.addEventListener( 'connected', ( event ){
			final xrInputSource = event.data as XRInputSource?;

			if ( xrInputSource?.hand != null && handModel.motionController == null) {

				handModel.xrInputSource = xrInputSource;

				// @todo Detect profile if not provided
				if ( profile == null || profile == 'spheres' ) {
					handModel.motionController = XRHandPrimitiveModel( handModel, controller, path, xrInputSource?.handedness, { 'primitive': 'sphere' } );
				} 
        else if ( profile == 'boxes' ) {
					handModel.motionController = XRHandPrimitiveModel( handModel, controller, path, xrInputSource?.handedness, { 'primitive': 'box' } );
				} 
        else if ( profile == 'mesh' ) {
					handModel.motionController = XRHandMeshModel( handModel, controller, path, xrInputSource?.handedness, gltfLoader, onLoad );
				}
			}

			controller.visible = true;
		});

		controller.addEventListener( 'disconnected', (event){
			controller.visible = false;
		} );

		return handModel;
	}
}