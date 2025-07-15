import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_xr/three_js_xr.dart';

final _matrix = Matrix4();
final _vector = Vector3();

///
/// Represents one of the hand model types {@link XRHandModelFactory} might produce
/// depending on the selected profile. `XRHandPrimitiveModel` represents a hand
/// with sphere or box primitives according to the selected `primitive` option.
///
/// @three_import import { XRHandPrimitiveModel } from 'three/addons/webxr/XRHandPrimitiveModel.js';
///
class XRHandPrimitiveModel extends MotionController{
  XRHandModel handModel;
  WebXRController controller;
  String? path;
  String? handedness;
  Texture? envMap;
  late InstancedMesh handMesh;
  Map<String,dynamic> options;

  final List<String> joints = [
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
    'pinky-finger-tip'
  ];

	///
	/// Constructs a new XR hand primitive model.
	///
	/// @param {XRHandModel} handModel - The hand model.
	/// @param {Group} controller - The WebXR controller.
	/// @param {string} path - The model path.
	/// @param {XRHandedness} handedness - The handedness of the XR input source.
	/// @param {XRHandPrimitiveModel~Options} options - The model options.
	///
	XRHandPrimitiveModel(this.handModel, this.controller, this.path, this.handedness, this.options ):super(){
		BufferGeometry? geometry;

		if (options['primitive'] == null || options['primitive'] == 'sphere' ) {
			geometry = SphereGeometry( 1, 10, 10 );
		} 
    else if( options['primitive'] == 'box' ) {
			geometry = BoxGeometry( 1, 1, 1 );
		}

		final material = MeshStandardMaterial();

		handMesh = InstancedMesh( geometry, material, 30 );
		handMesh.frustumCulled = false;
		handMesh.instanceMatrix?.setUsage( DynamicDrawUsage ); // will be updated every frame
		handMesh.castShadow = true;
		handMesh.receiveShadow = true;
		handModel.add( handMesh );
	}

	///
	/// Updates the mesh based on the tracked XR joints data.
	///
  @override
	void updateMesh() {
		final defaultRadius = 0.008;
		final joints = controller.children;//.joints as Map<String,Object3D>;

		int count = 0;

		for (int i = 0; i < this.joints.length; i ++ ) {
			final joint = joints[i];//[ this.joints[ i ] ];

			if ( joint.visible == true) {
				_vector.setScalar( joint.userData['jointRadius'] ?? defaultRadius );
				_matrix.compose( joint.position, joint.quaternion, _vector );
				handMesh.setMatrixAt( i, _matrix );

				count ++;
			}
		}

		handMesh.count = count;
		handMesh.instanceMatrix?.needsUpdate = true;
	}
}
