
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/models/controller/visual_response.dart';
import 'package:three_js_xr/other/constants.dart';

class Component {
  late Map<String,dynamic> values; 
  Map<String,VisualResponse> visualResponses = {};
  Map<String,dynamic> componentDescription;
  late Map<String,dynamic> gamepadIndices;
  dynamic componentId;
  dynamic id;
  dynamic type;
  dynamic rootNodeName;
  dynamic touchPointNodeName;

  Object3D? touchPointNode;

  ///
  /// @param {Object} componentId - Id of the component
  /// @param {Object} componentDescription - Description of the component to be created
  ///
  Component(dynamic componentId, this.componentDescription) {
    if (componentDescription['visualResponses'] == null
     || componentDescription['gamepadIndices'] == null
     || componentDescription['gamepadIndices'].keys.isEmpty) {
      throw('Invalid arguments supplied');
    }

    id = componentId;
    type = componentDescription['type'];
    rootNodeName = componentDescription['rootNodeName'];
    touchPointNodeName = componentDescription['touchPointNodeName'];

    // Build all the visual responses for this component
    componentDescription['visualResponses'].forEach((responseName,values){
      final visualResponse = VisualResponse(componentDescription['visualResponses'][responseName]);
      visualResponses[responseName] = visualResponse;
    });

    // Set default values
    gamepadIndices = componentDescription['gamepadIndices'];

    values = {
      'state': constants['ComponentState']['DEFAULT'],
      'button': (gamepadIndices['button'] != null) ? 0 : null,
      'xAxis': (gamepadIndices['xAxis'] != null) ? 0 : null,
      'yAxis': (gamepadIndices['yAxis'] != null) ? 0 : null
    };
  }

  get data {
    final data = { 'id': id, ...values };
    return data;
  }

  ///
  /// @description Poll for updated data based on current gamepad state
  /// @param {Object} gamepad - The gamepad object from which the component data should be polled
  ///
  updateFromGamepad(gamepad) {
    // Set the state to default before processing other data sources
    values['state'] = constants['ComponentState']['DEFAULT'];

    // Get and normalize button
    if (gamepadIndices['button'] != null
        && gamepad.buttons.length > gamepadIndices['button']) {
      final gamepadButton = gamepad.buttons[gamepadIndices['button']];
      values['button'] = gamepadButton.value;
      values['button'] = (values['button'] < 0) ? 0 : values['button'];
      values['button'] = (values['button'] > 1) ? 1 : values['button'];

      // Set the state based on the button
      if (gamepadButton.pressed || values['button'] == 1) {
        values['state'] = constants['ComponentState']['PRESSED'];
      } else if (gamepadButton.touched || values['button'] > constants['ButtonTouchThreshold']) {
        values['state'] = constants['ComponentState']['TOUCHED'];
      }
    }

    // Get and normalize x axis value
    if (gamepadIndices['xAxis'] != null
        && gamepad.axes.length > gamepadIndices['xAxis']) {
      values['xAxis'] = gamepad.axes[gamepadIndices['xAxis']];
      values['xAxis'] = (values['xAxis'] < -1) ? -1 : values['xAxis'];
      values['xAxis'] = (values['xAxis'] > 1) ? 1 : values['xAxis'];

      // If the state is still default, check if the xAxis makes it touched
      if (values['state'] == constants['ComponentState']['DEFAULT']
        && values['xAxis'].abs() > constants['AxisTouchThreshold']) {
        values['state'] = constants['ComponentState']['TOUCHED'];
      }
    }

    // Get and normalize Y axis value
    if (gamepadIndices['yAxis'] != null
        && gamepad.axes.length > gamepadIndices['yAxis']) {
      values['yAxis'] = gamepad.axes[gamepadIndices['yAxis']];
      values['yAxis'] = (values['yAxis'] < -1) ? -1 : values['yAxis'];
      values['yAxis'] = (values['yAxis'] > 1) ? 1 : values['yAxis'];

      // If the state is still default, check if the yAxis makes it touched
      if (values['state'] == constants['ComponentState']['DEFAULT']
        && values['yAxis'].abs() > constants['AxisTouchThreshold']) {
        values['state'] = constants['ComponentState']['TOUCHED'];
      }
    }

    // Update the visual response weights based on the current component data
    visualResponses.forEach((key,visualResponse){
      visualResponse.updateFromComponent(values);
    });
  }
}