import 'dart:async';
import 'package:flutter/services.dart';
import 'shared.dart';

final ThreeJsSensors tjSensors = ThreeJsSensors();
const MethodChannel _methodChannel = MethodChannel('tjs_sensors/method');
const EventChannel _accelerometerEventChannel = EventChannel('tjs_sensors/accelerometer');
const EventChannel _gyroscopeEventChannel = EventChannel('tjs_sensors/gyroscope');
const EventChannel _magnetometerEventChannel = EventChannel('tjs_sensors/magnetometer');
const EventChannel _userAccelerometerEventChannel = EventChannel('tjs_sensors/user_accelerometer');
const EventChannel _absoluteOrientationChannel = EventChannel('tjs_sensors/absolute_orientation');
const EventChannel _screenOrientationChannel = EventChannel('tjs_sensors/screen_orientation');

class ThreeJsSensors {
  Stream<AccelerometerEvent>? _accelerometerEvents;
  Stream<GyroscopeEvent>? _gyroscopeEvents;
  Stream<UserAccelerometerEvent>? _userAccelerometerEvents;
  Stream<MagnetometerEvent>? _magnetometerEvents;
  Stream<AbsoluteOrientationEvent>? _absoluteOrientationEvents;
  Stream<ScreenOrientationEvent>? _screenOrientationEvents;

  final List<int> _typesList = [1,2,4,10,15,11];

  /// Determines whether sensor is available.
  Future<bool> isSensorAvailable(SensorType sensorType) async {
    final available = await _methodChannel.invokeMethod('isSensorAvailable', _typesList[sensorType.index]);
    return available;
  }

  /// Determines whether accelerometer is available.
  Future<bool> isAccelerometerAvailable() => isSensorAvailable(SensorType.accelerometer);

  /// Determines whether magnetometer is available.
  Future<bool> isMagnetometerAvailable() => isSensorAvailable(SensorType.magnetometer);

  /// Determines whether gyroscope is available.
  Future<bool> isGyroscopeAvailable() => isSensorAvailable(SensorType.gyroscope);

  /// Determines whether user accelerometer is available.
  Future<bool> isUserAccelerationAvailable() => isSensorAvailable(SensorType.userAccelerometer);

  /// Determines whether orientation is available.
  Future<bool> isOrientationAvailable() => isSensorAvailable(SensorType.orientation);

  /// Determines whether absolute orientation is available.
  Future<bool> isAbsoluteOrientationAvailable() => isSensorAvailable(SensorType.absoluteOrientation);

  /// Change the update interval of sensor. The units are in microseconds.
  Future _setSensorUpdateInterval(SensorType sensorType, Duration interval) async {
    await _methodChannel.invokeMethod(
      'setSensorUpdateInterval', 
      {"sensorType": _typesList[sensorType.index], "interval": interval.frequency});
  }

  /// A broadcast stream of events from the device accelerometer.
  Stream<AccelerometerEvent> accelerometer({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    _accelerometerEvents ??= _accelerometerEventChannel.receiveBroadcastStream().map((dynamic event) => AccelerometerEvent.fromList(event.cast<double>()));
    _setSensorUpdateInterval(SensorType.accelerometer,samplingPeriod);
    return _accelerometerEvents!;
  }

  /// A broadcast stream of events from the device gyroscope.
  Stream<GyroscopeEvent> gyroscope({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    _gyroscopeEvents ??= _gyroscopeEventChannel.receiveBroadcastStream().map((dynamic event) => GyroscopeEvent.fromList(event.cast<double>()));
    _setSensorUpdateInterval(SensorType.gyroscope,samplingPeriod);
    return _gyroscopeEvents!;
  }

  /// Events from the device accelerometer with gravity removed.
  Stream<UserAccelerometerEvent> userAccelerometer({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    _userAccelerometerEvents ??= _userAccelerometerEventChannel.receiveBroadcastStream().map((dynamic event) => UserAccelerometerEvent.fromList(event.cast<double>())); 
    _setSensorUpdateInterval(SensorType.userAccelerometer,samplingPeriod);
    return _userAccelerometerEvents!;
  }

  /// A broadcast stream of events from the device magnetometer.
  Stream<MagnetometerEvent> magnetometer({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    _magnetometerEvents ??= _magnetometerEventChannel.receiveBroadcastStream().map((dynamic event) => MagnetometerEvent.fromList(event.cast<double>()));
    _setSensorUpdateInterval(SensorType.magnetometer,samplingPeriod);
    return _magnetometerEvents!;
  }

  /// The current absolute orientation of the device.
  Stream<AbsoluteOrientationEvent> absoluteOrientation({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    _absoluteOrientationEvents ??= _absoluteOrientationChannel.receiveBroadcastStream().map((dynamic event) => AbsoluteOrientationEvent.fromList(event.cast<double>()));
    _setSensorUpdateInterval(SensorType.absoluteOrientation,samplingPeriod);
    return _absoluteOrientationEvents!;
  }

  /// The rotation of the screen from its "natural" orientation.
  Stream<ScreenOrientationEvent> screenOrientation({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    _screenOrientationEvents ??= _screenOrientationChannel.receiveBroadcastStream().map((dynamic event) => ScreenOrientationEvent(event as double?));
    _setSensorUpdateInterval(SensorType.orientation,samplingPeriod);
    return _screenOrientationEvents!;
  }
}