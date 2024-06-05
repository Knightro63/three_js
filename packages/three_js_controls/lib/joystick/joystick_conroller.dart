

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

enum JoystickMoveDirectional {
  MOVE_UP,
  MOVE_UP_LEFT,
  MOVE_UP_RIGHT,
  MOVE_RIGHT,
  MOVE_DOWN,
  MOVE_DOWN_RIGHT,
  MOVE_DOWN_LEFT,
  MOVE_LEFT,
  IDLE
}

class JoystickDirectionalEvent {
  final JoystickMoveDirectional directional;
  final double intensity;
  final double radAngle;

  JoystickDirectionalEvent({
    required this.directional,
    this.intensity = 0.0,
    this.radAngle = 0.0,
  });
}

enum ActionEvent { DOWN, UP, MOVE }

class JoystickActionEvent {
  final dynamic id;
  final double intensity;
  final double radAngle;
  final ActionEvent event;

  JoystickActionEvent({
    this.id,
    this.intensity = 0.0,
    this.radAngle = 0.0,
    required this.event,
  });
}

mixin JoystickListener {
  void joystickChangeDirectional(JoystickDirectionalEvent event) {}
  void joystickAction(JoystickActionEvent event) {}
  void moveTo(Vector2 position) {}
}

abstract class JoystickController extends Event {
  final List<JoystickListener> _observers = [];

  KeyboardConfig keyboardConfig = KeyboardConfig(enable: false);

  void joystickChangeDirectional(JoystickDirectionalEvent event) {
    for (var o in _observers) {
      o.joystickChangeDirectional(event);
    }
  }

  void joystickAction(JoystickActionEvent event) {
    for (var o in _observers) {
      o.joystickAction(event);
    }
  }

  void moveTo(Vector2 event) {
    for (var o in _observers) {
      o.moveTo(event);
    }
  }

  void addObserver(JoystickListener listener) {
    _observers.add(listener);
  }

  void removeObserver(JoystickListener listener) {
    _observers.remove(listener);
  }

  void cleanObservers() {
    _observers.clear();
  }

  bool containObserver(JoystickListener listener) {
    return _observers.contains(listener);
  }

  @override
  int get priority {
    return LayerPriority.getJoystickPriority(gameRef.highestPriority);
  }

  @override
  PositionType get positionType => PositionType.viewport;

  @override
  bool hasGesture() => true;
}