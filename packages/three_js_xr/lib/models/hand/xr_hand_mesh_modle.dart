import 'package:three_js_advanced_loaders/gltf/gltf_loader.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/three_js_xr.dart';

const DEFAULT_HAND_PROFILE_PATH = 'https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles/generic-hand/';

///
/// Represents one of the hand model types {@link XRHandModelFactory} might produce
/// depending on the selected profile. `XRHandMeshModel` represents a hand with a
/// custom asset.
///
/// @three_import import { XRHandMeshModel } from 'three/addons/webxr/XRHandMeshModel.js';
///
class XRHandMeshModel extends MotionController{
  GLTFLoader? loader;
  Function? onLoad;
  WebXRController controller;
  XRHandModel handModel;
  List<Object3D?>? bones;
  String? path;
  XRHandedness? hardness;

	/// Constructs a new XR hand mesh model.
	///
	/// @param {XRHandModel} handModel - The hand model.
	/// @param {Group} controller - The WebXR controller.
	/// @param {?string} path - The model path.
	/// @param {XRHandedness} handedness - The handedness of the XR input source.
	/// @param {?Loader} [loader=null] - The loader. If not provided, an instance of `GLTFLoader` will be used to load models.
	/// @param {?Function} [onLoad=null] - A callback that is executed when a controller model has been loaded.
	///
	XRHandMeshModel(this.handModel, this.controller, this.path, handedness, [this.loader, this.onLoad]){
		if ( loader == null ) {
			loader = GLTFLoader();
			loader?.setPath( path ?? DEFAULT_HAND_PROFILE_PATH );
		}

		loader!.unknown('$handedness.glb').then((gltf){
			final object = gltf!.scene.children[ 0 ];
			handModel.add( object );

			final mesh = object.getObjectByProperty( 'type', 'SkinnedMesh' );
			mesh?.frustumCulled = false;
			mesh?.castShadow = true;
			mesh?.receiveShadow = true;

			const joints = [
				'wrist',
				'thumb-metacarpal',
				'thumb-phalanx-proximal',
				'thumb-phalanx-distal',
				'thumb-tip',
				'index-finger-metacarpal',
				'index-finger-phalanx-proximal',
				'index-finger-phalanx-intermediate',
				'index-finger-phalanx-distal',
				'index-finger-tip',
				'middle-finger-metacarpal',
				'middle-finger-phalanx-proximal',
				'middle-finger-phalanx-intermediate',
				'middle-finger-phalanx-distal',
				'middle-finger-tip',
				'ring-finger-metacarpal',
				'ring-finger-phalanx-proximal',
				'ring-finger-phalanx-intermediate',
				'ring-finger-phalanx-distal',
				'ring-finger-tip',
				'pinky-finger-metacarpal',
				'pinky-finger-phalanx-proximal',
				'pinky-finger-phalanx-intermediate',
				'pinky-finger-phalanx-distal',
				'pinky-finger-tip',
			];

			joints.forEach((jointName){
				final bone = object.getObjectByName( jointName );

				if ( bone != null ) {
					bone.userData['jointName'] = jointName;
				} 
        else {
					console.warning('Couldn\'t find $jointName in $handedness hand mesh');
				}

				bones?.add( bone );
			});

			onLoad?.call( object );
		});
	}

	///
	/// Updates the mesh based on the tracked XR joints data.
	///
  @override
	void updateMesh() {
		final xrJoints = controller.children;//.userData['joints'];

		for (int i = 0; i < (bones?.length ?? 0); i ++ ) {
			final bone = bones?[i];

			if ( bone != null) {
				final xrJoint = xrJoints[i];//bone.userData['jointName'] ];

				if ( xrJoint.visible == true) {
					final position = xrJoint.position;

					bone.position.setFrom( position );
					bone.quaternion.setFrom( xrJoint.quaternion );
					// bone.scale.setScalar( XRJoint.jointRadius || defaultRadius );
				}
			}
		}
	}
}