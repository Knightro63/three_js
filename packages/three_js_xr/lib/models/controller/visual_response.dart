import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_xr/other/constants.dart';

final Map<String, dynamic> defaultComponentValues = {
  'xAxis': 0,
  'yAxis': 0,
  'button': 0,
  'state': constants['ComponentState']['DEFAULT']
};

class VisualResponse {
  double value = 0;
  String? componentProperty;
  List? states;
  String? valueNodeName;
  String? valueNodeProperty;
  String? maxNodeName;
  String? minNodeName;

  Object3D? valueNode;
  Object3D? maxNode;
  Object3D? minNode;

  VisualResponse(Map visualResponseDescription) {
    componentProperty = visualResponseDescription['componentProperty'];
    states = visualResponseDescription['states'];
    valueNodeName = visualResponseDescription['valueNodeName'];
    valueNodeProperty = visualResponseDescription['valueNodeProperty'];

    if (valueNodeProperty == constants['VisualResponseProperty']['TRANSFORM']) {
      minNodeName = visualResponseDescription['minNodeName'];
      maxNodeName = visualResponseDescription['maxNodeName'];
    }

    updateFromComponent(defaultComponentValues);
  }

  ///
  /// Computes the visual response's interpolation weight based on component state
  /// @param {Object} componentValues - The component from which to update
  /// @param {number} xAxis - The reported X axis value of the component
  /// @param {number} yAxis - The reported Y axis value of the component
  /// @param {number} button - The reported value of the component's button
  /// @param {string} state - The component's active state
  ///
  void updateFromComponent(Map values) {
    final state = values['state'];
    final button = values['button'];
    final normalized = normalizeAxes(values['xAxis'], values['yAxis']);
    final normalizedXAxis = normalized['normalizedXAxis'];
    final normalizedYAxis = normalized['normalizedYAxis'];

    switch (componentProperty) {
      case 'xAxis':
        value = (states!.contains(state)) ? normalizedXAxis : 0.5;
        break;
      case 'yAxis':
        value = (states!.contains(state)) ? normalizedYAxis : 0.5;
        break;
      case 'button':
        value = (states!.contains(state)) ? button : 0;
        break;
      case 'state':
        if (valueNodeProperty == constants['VisualResponseProperty']['VISIBILITY']) {
          value = states!.contains(state)? 1:0;
        } 
        else {
          value = states!.contains(state) ? 1.0 : 0.0;
        }
        break;
      default:
        throw('Unexpected visualResponse componentProperty $componentProperty');
    }
  }

  static Map<String,dynamic> normalizeAxes([double? x, double? y]) {
    x ??= 0;
    y ??= 0;
    double xAxis = x;
    double yAxis = y;

    // Determine if the point is outside the bounds of the circle
    // and, if so, place it on the edge of the circle
    final hypotenuse = math.sqrt((x * x) + (y * y));
    if (hypotenuse > 1) {
      final theta = math.atan2(y, x);
      xAxis = math.cos(theta);
      yAxis = math.sin(theta);
    }

    // Scale and move the circle so values are in the interpolation range.  The circle's origin moves
    // from (0, 0) to (0.5, 0.5). The circle's radius scales from 1 to be 0.5.
    final result = {
      'normalizedXAxis': (xAxis * 0.5) + 0.5,
      'normalizedYAxis': (yAxis * 0.5) + 0.5
    };
    return result;
  }
}