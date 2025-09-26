import 'package:three_js_advanced_loaders/gltf/gltf_loader.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/app/index.dart';
import 'package:three_js_xr/models/controller/motion_controllers_modle.dart';
import 'package:three_js_xr/models/controller/xr_controller_modle.dart';
import 'package:three_js_xr/other/constants.dart';
import 'package:three_js_xr/renderer/index.dart';

///
/// Allows to create controller models for WebXR controllers that can be added as a visual
/// representation to your scene. `XRControllerModelFactory` will automatically fetch controller
/// models that match what the user is holding as closely as possible. The models should be
/// attached to the object returned from getControllerGrip in order to match the orientation of
/// the held device.
/// 
/// This module depends on the [motion-controllers]{@link https://github.com/immersive-web/webxr-input-profiles/blob/main/packages/motion-controllers/README.md}
/// third-part library.
/// 
/// ```js
/// const controllerModelFactory = new XRControllerModelFactory();
/// 
/// const controllerGrip = renderer.xr.getControllerGrip( 0 );
/// controllerGrip.add( controllerModelFactory.createControllerModel( controllerGrip ) );
/// scene.add( controllerGrip );
/// ```
/// 
/// @three_import import { XRControllerModelFactory } from 'three/addons/webxr/XRControllerModelFactory.js';
class XRControllerModelFactory {
  String path = DEFAULT_PROFILES_PATH;
  Map _assetCache = {};
  GLTFLoader? gltfLoader;
  Function? onLoad;

	///
  /// Constructs a new XR controller model factory.
  /// 
  /// @param {?GLTFLoader} [gltfLoader=null] - A glTF loader that is used to load controller models.
  /// @param {?Function} [onLoad=null] - A callback that is executed when a controller model has been loaded.
  /// 
	XRControllerModelFactory([this.gltfLoader, this.onLoad ]) {
		gltfLoader ??= GLTFLoader();
	}

	///
  /// Sets the path to the model repository.
  /// 
  /// @param {string} path - The path to set.
  /// @return {XRControllerModelFactory} A reference to this instance.
  /// 
	XRControllerModelFactory setPath( path ) {
		this.path = path;
		return this;
	}

	///
  /// Creates a controller model for the given WebXR controller.
  /// 
  /// @param {Group} controller - The controller.
  /// @return {XRControllerModel} The XR controller model.
  /// 
	XRControllerModel createControllerModel(WebXRController controller ) {
		final controllerModel = XRControllerModel();
		Object3D? scene;

		controller.addEventListener( 'connected', ( event ){
			final xrInputSource = event.data as XRInputSource;

			if ( xrInputSource.targetRayMode != 'tracked-pointer' || xrInputSource.gamepad == null || xrInputSource.hand != null) return;

			fetchProfile( xrInputSource, path, DEFAULT_PROFILE ).then( (map){
				controllerModel.motionController = MotionController(
					xrInputSource,
					map['profile'],
					map['assetPath']
				);

				final cachedAsset = _assetCache[ controllerModel.motionController!.assetUrl ];
				if ( cachedAsset != null) {
					scene = cachedAsset.scene.clone();
					addAssetSceneToControllerModel( controllerModel, scene );
					onLoad?.call( scene );
				} 
        else {
					gltfLoader!.setPath( '' );
					gltfLoader!.unknown( controllerModel.motionController!.assetUrl).then(( asset ){
						_assetCache[ controllerModel.motionController!.assetUrl ] = asset;
						scene = asset?.scene.clone();
						addAssetSceneToControllerModel( controllerModel, scene );
						onLoad?.call( scene );
					});
				}
			});
		} );

		controller.addEventListener( 'disconnected', (event){
			controllerModel.motionController = null;
			controllerModel.remove( scene! );
			scene = null;
		});

		return controllerModel;
	}
}