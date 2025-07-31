import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/models/component.dart';
import 'package:three_js_xr/models/controller/motion_controllers_modle.dart';
import 'package:three_js_xr/other/constants.dart';

///
/// Represents a XR controller model.
///
/// @augments Object3D
/// 
class XRControllerModel extends Object3D {
  ///
  /// The motion controller.
  ///
  /// @type {?MotionController}
  /// @default null
  /// 
  MotionController? motionController;

  ///
  /// The controller's environment map.
  ///
  /// @type {?Texture}
  /// @default null
  /// 
  Texture? envMap;

	///
	/// Constructs a new XR controller model.
	/// 
	XRControllerModel():super();

	///
	/// Sets an environment map that is applied to the controller model.
	///
	/// @param {?Texture} envMap - The environment map to apply.
	/// @return {XRControllerModel} A reference to this instance.
	/// 
	XRControllerModel setEnvironmentMap(Texture? envMap ) {
		if ( this.envMap == envMap ) {
			return this;
		}

		this.envMap = envMap;
		traverse( ( child ) {
			if ( child is Mesh ) {
				child.material!.envMap = this.envMap;
				child.material!.needsUpdate = true;
			}
		} );

		return this;
	}

	///
	/// Overwritten with a custom implementation. Polls data from the XRInputSource and updates the
	/// model's components to match the real world data.
	///
	/// @param {boolean} [force=false] - When set to `true`, a recomputation of world matrices is forced even
	/// when {@link Object3D#matrixWorldAutoUpdate} is set to `false`.
	///
  @override
	void updateMatrixWorld([bool force = false]) {
		super.updateMatrixWorld( force );
		if (motionController == null) return;

		// Cause the MotionController to poll the Gamepad for data
		motionController?.updateFromGamepad();
		// Update the 3D model to reflect the button, thumbstick, and touchpad state
		motionController?.components.forEach( (key,component ){
      component as Component;
			// Update node data based on the visual responses' current states
			component.visualResponses.forEach( (key, visualResponse ){
        //visualResponse as VisualResponse;
				final valueNode = visualResponse.valueNode;
        final minNode = visualResponse.minNode;
        final maxNode = visualResponse.maxNode;
        final value = visualResponse.value;
        final valueNodeProperty = visualResponse.valueNodeProperty;

				// Skip if the visual response node is not found. No error is needed,
				// because it will have been reported at load time.
				if (valueNode == null) return;

				// Calculate the new properties based on the weight supplied
				if ( valueNodeProperty == constants['VisualResponseProperty']['VISIBILITY'] ) {
					valueNode.visible = value == 1?true:false;
				} 
        else if ( valueNodeProperty == constants['VisualResponseProperty']['TRANSFORM'] ) {
					valueNode.quaternion.slerpQuaternions(
						minNode!.quaternion,
						maxNode!.quaternion,
						value
					);

					valueNode.position.lerpVectors(
						minNode.position,
						maxNode.position,
						value
					);
				}
			});
    });
	}

}
