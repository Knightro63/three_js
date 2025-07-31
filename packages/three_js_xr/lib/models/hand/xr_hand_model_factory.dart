import 'package:three_js_advanced_loaders/three_js_advanced_loaders.dart';
import 'package:three_js_xr/three_js_xr.dart';

enum XRProfiles{spheres,boxes,mesh}

class XRHandModelFactory {
  GLTFLoader? gltfLoader;
  String? path;
  Function? onLoad;

	XRHandModelFactory([this.gltfLoader, this.onLoad ]);

	XRHandModelFactory setPath(String path ) {
		this.path = path;
		return this;
	}

	XRHandModel createHandModel(WebXRController controller, [XRProfiles? profile] ) {
		final handModel = XRHandModel( controller );

		controller.addEventListener( 'connected', ( event ){
			final xrInputSource = event.data as XRInputSource?;

			if ( xrInputSource?.hand != null && handModel.motionController == null) {

				handModel.xrInputSource = xrInputSource;

				// @todo Detect profile if not provided
				if ( profile == null || profile == XRProfiles.spheres ) {
					handModel.motionController = XRHandPrimitiveModel( handModel, controller, path, xrInputSource?.handedness, { 'primitive': 'sphere' } );
				} 
        else if ( profile == XRProfiles.boxes ) {
					handModel.motionController = XRHandPrimitiveModel( handModel, controller, path, xrInputSource?.handedness, { 'primitive': 'box' } );
				} 
        else if ( profile == XRProfiles.mesh ) {
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