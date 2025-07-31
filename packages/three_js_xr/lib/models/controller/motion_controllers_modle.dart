import 'package:three_js_xr/app/web/xr_webgl_bindings.dart';
import 'package:three_js_xr/models/component.dart';

///
/// @description Builds a motion controller with components and visual responses based on the
/// supplied profile description. Data is polled from the xrInputSource's gamepad.
/// @author Nell Waliczek / https://github.com/NellWaliczek
///
class MotionController {
  XRInputSource? xrInputSource;
  String? assetUrl;
  Map components = {};
  Map<String,dynamic>? profile; 
  dynamic id;
  dynamic layoutDescription;

  ///
  /// @param {Object} xrInputSource - The XRInputSource to build the MotionController around
  /// @param {Object} profile - The best matched profile description for the supplied xrInputSource
  /// @param {string} assetUrl
  ///
  MotionController([this.xrInputSource, this.profile, this.assetUrl]) {
    id = profile?['profileId'];

    // Build child components as described in the profile description
    layoutDescription = profile?['layouts'][xrInputSource?.handedness];
    layoutDescription['components'].forEach((componentId,value){
      final componentDescription = layoutDescription['components'][componentId];
      components[componentId] = Component(componentId, componentDescription);
    });

    // Initialize components based on current gamepad state
    updateFromGamepad();
  }

  get gripSpace => xrInputSource?.gripSpace;
  get targetRaySpace => xrInputSource?.targetRaySpace;

  ///
  /// @description Returns a subset of component data for simplified debugging
  ///
  get data {
    const data = [];
    components.forEach((key,component){
      data.add(component.data);
    });
    return data;
  }

  ///
  /// @description Poll for updated data based on current gamepad state
  ///
  void updateFromGamepad() {
    components.forEach((key,component){
      component.updateFromGamepad(xrInputSource?.gamepad);
    });
  }

  void updateMesh(){
    throw("Not Implimented!");
  }
}