import 'dart:async';
import 'dart:developer' as developer;
import 'dart:js_interop';

import '../shared.dart';
import 'web_sensors_interop.dart';

class ThreeJsSensors {
  StreamController<AccelerometerEvent>? _accelerometerStreamController;
  late Stream<AccelerometerEvent> _accelerometerResultStream;
  StreamController<UserAccelerometerEvent>? _userAccelerometerStreamController;
  late Stream<UserAccelerometerEvent> _userAccelerometerResultStream;
  StreamController<GyroscopeEvent>? _gyroscopeEventStreamController;
  late Stream<GyroscopeEvent> _gyroscopeEventResultStream;
  StreamController<MagnetometerEvent>? _magnetometerStreamController;
  late Stream<MagnetometerEvent> _magnetometerResultStream;

  StreamController<AbsoluteOrientationEvent>? _absoluteOrientationStreamController;
  late Stream<AbsoluteOrientationEvent> _absoluteOrientationResultStream;

  StreamController<ScreenOrientationEvent>? _screenOrientationStreamController;
  late Stream<ScreenOrientationEvent> _screenOrientationResultStream;

  /// Determines whether sensor is available.
  Future<bool> isSensorAvailable(SensorType sensorType) async {
    return true;
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
  
  void _featureDetected(
    Function initSensor, {
    String? apiName,
    String? permissionName,
    Function? onError,
  }) {
    try {
      initSensor();
    } 
    on DOMException catch (e) {
      if (onError != null) {
        onError();
      }

      // Handle construction errors.
      //
      // If a feature policy blocks use of a feature it is because your code
      // is inconsistent with the policies set on your server.
      // This is not something that would ever be shown to a user.
      // See Feature-Policy for implementation instructions in the browsers.
      switch (e.name) {
        case 'TypeError':
          // if this feature is not supported or Flag is not enabled yet!
          developer.log(
            '$apiName is not supported by the User Agent.',
            error: '${e.name}: ${e.message}',
          );
        case 'SecurityError':
          // See the note above about feature policy.
          developer.log(
            '$apiName construction was blocked by a feature policy.',
            error: '${e.name}: ${e.message}',
          );
        default:
          // if this is unknown error, convert DOMException to Exception
          developer.log('Unknown error happened, rethrowing.');
          throw Exception('${e.name}: ${e.message}');
      }
    } on Error catch (_) {
      // DOMException is not caught as in release build
      // so we need to catch it as Error
      if (onError != null) {
        onError();
      }
    }
  }

  Stream<AccelerometerEvent> accelerometer({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }){
    if (_accelerometerStreamController == null) {
      _accelerometerStreamController = StreamController<AccelerometerEvent>();
      _featureDetected(
        () {
          final accelerometer = Accelerometer(
            SensorOptions(
              frequency: samplingPeriod.frequency,
            ),
          );

          accelerometer.start();

          accelerometer.onreading = (Event _) {
            _accelerometerStreamController!.add(
              AccelerometerEvent(
                accelerometer.x,
                accelerometer.y,
                accelerometer.z,
              ),
            );
          }.toJS;

          accelerometer.onerror = (SensorErrorEvent e) {
            developer.log(
              'The accelerometer API is supported but something is wrong!',
              error: e.error.message,
            );
          }.toJS;
        },
        apiName: 'Accelerometer()',
        permissionName: 'accelerometer',
        onError: () {
          _accelerometerStreamController!.add(AccelerometerEvent(0, 0, 0));
        },
      );
      _accelerometerResultStream =
          _accelerometerStreamController!.stream.asBroadcastStream();

      _accelerometerStreamController!.onCancel = () {
        _accelerometerStreamController!.close();
      };
    }

    return _accelerometerResultStream;
  }

  Stream<GyroscopeEvent> gyroscope({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }){
    if (_gyroscopeEventStreamController == null) {
      _gyroscopeEventStreamController = StreamController<GyroscopeEvent>();
      _featureDetected(
        () {
          final gyroscope = Gyroscope(
            SensorOptions(
              frequency: samplingPeriod.frequency,
            ),
          );

          gyroscope.start();

          gyroscope.onreading = (Event _) {
            _gyroscopeEventStreamController!.add(
              GyroscopeEvent(
                gyroscope.x,
                gyroscope.y,
                gyroscope.z,
              ),
            );
          }.toJS;

          gyroscope.onerror = (SensorErrorEvent e) {
            developer.log(
              'The gyroscope API is supported but something is wrong!',
              error: e.error.message,
            );
          }.toJS;
        },
        apiName: 'Gyroscope()',
        permissionName: 'gyroscope',
        onError: () {
          _gyroscopeEventStreamController!.add(GyroscopeEvent(0, 0, 0));
        },
      );
      _gyroscopeEventResultStream =
          _gyroscopeEventStreamController!.stream.asBroadcastStream();

      _gyroscopeEventStreamController!.onCancel = () {
        _gyroscopeEventStreamController!.close();
      };
    }

    return _gyroscopeEventResultStream;
  }

  Stream<UserAccelerometerEvent> userAccelerometer({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }){
    if (_userAccelerometerStreamController == null) {
      _userAccelerometerStreamController =
          StreamController<UserAccelerometerEvent>();
      _featureDetected(
        () {
          final linearAccelerationSensor = LinearAccelerationSensor(
            SensorOptions(
              frequency: samplingPeriod.frequency,
            ),
          );

          linearAccelerationSensor.start();

          linearAccelerationSensor.onreading = (Event _) {
            _gyroscopeEventStreamController!.add(
              GyroscopeEvent(
                linearAccelerationSensor.x,
                linearAccelerationSensor.y,
                linearAccelerationSensor.z,
              ),
            );
          }.toJS;

          linearAccelerationSensor.onerror = (SensorErrorEvent e) {
            developer.log(
              'The linear acceleration API is supported but something is wrong!',
              error: e.error.message,
            );
          }.toJS;
        },
        apiName: 'LinearAccelerationSensor()',
        permissionName: 'accelerometer',
        onError: () {
          _userAccelerometerStreamController!
              .add(UserAccelerometerEvent(0, 0, 0));
        },
      );
      _userAccelerometerResultStream =
          _userAccelerometerStreamController!.stream.asBroadcastStream();

      _userAccelerometerStreamController!.onCancel = () {
        _userAccelerometerStreamController!.close();
      };
    }

    return _userAccelerometerResultStream;
  }

  Stream<MagnetometerEvent> magnetometer({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }){
    // The Magnetometer API is not supported by any modern browser.
    if (_magnetometerStreamController == null) {
      _magnetometerStreamController = StreamController<MagnetometerEvent>();
      _featureDetected(
        () {
          final magnetometerSensor = Magnetometer(
            SensorOptions(
              frequency: samplingPeriod.frequency,
            ),
          );

          magnetometerSensor.start();

          magnetometerSensor.onreading = (Event _) {
            _gyroscopeEventStreamController!.add(
              GyroscopeEvent(
                magnetometerSensor.x,
                magnetometerSensor.y,
                magnetometerSensor.z,
              ),
            );
          }.toJS;

          magnetometerSensor.onerror = (SensorErrorEvent e) {
            developer.log(
              'The magnetometer API is supported but something is wrong!',
              error: e,
            );
          }.toJS;
        },
        apiName: 'Magnetometer()',
        permissionName: 'magnetometer',
        onError: () {
          _magnetometerStreamController!.add(MagnetometerEvent(0, 0, 0));
        },
      );
      _magnetometerResultStream =
          _magnetometerStreamController!.stream.asBroadcastStream();

      _magnetometerStreamController!.onCancel = () {
        _magnetometerStreamController!.close();
      };
    }

    return _magnetometerResultStream;
  }

  Stream<AbsoluteOrientationEvent> absoluteOrientation({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }){
    if (_absoluteOrientationStreamController == null) {
      _absoluteOrientationStreamController = StreamController<AbsoluteOrientationEvent>();
      _featureDetected(
        () {
          final absoluteOrientation = AbsoluteOrientationSensor(
            SensorOptions(
              frequency: samplingPeriod.frequency,
            ),
          );

          absoluteOrientation.start();

          absoluteOrientation.onreading = (Event _) {
            final q = absoluteOrientation.quant.toDart;
            _absoluteOrientationStreamController!.add(
              
              AbsoluteOrientationEvent(
                q[0] as double,
                q[1] as double,
                q[2] as double,
              ),
            );
          }.toJS;

          absoluteOrientation.onerror = (SensorErrorEvent e) {
            developer.log(
              'The absoluteOrientation API is supported but something is wrong!',
              error: e.error.message,
            );
          }.toJS;
        },
        apiName: 'AbsoluteOrientationSensor()',
        permissionName: 'accelerometer',
        onError: () {
          _absoluteOrientationStreamController!.add(AbsoluteOrientationEvent(0, 0, 0));
        },
      );
      _absoluteOrientationResultStream =
          _absoluteOrientationStreamController!.stream.asBroadcastStream();

      _absoluteOrientationStreamController!.onCancel = () {
        _absoluteOrientationStreamController!.close();
      };
    }

    return _absoluteOrientationResultStream;
  }

  Stream<ScreenOrientationEvent> screenOrientation({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }){
    if (_screenOrientationStreamController == null) {
      _screenOrientationStreamController = StreamController<ScreenOrientationEvent>();
      _featureDetected(
        () {
          _screenOrientationStreamController!.add(
            ScreenOrientationEvent(0),
          );
          // screenOrientation.onerror = (SensorErrorEvent e) {
          //   developer.log(
          //     'The absoluteOrientation API is supported but something is wrong!',
          //     error: e.error.message,
          //   );
          // }.toJS;
        },
        apiName: 'ScreenOrientation()',
        permissionName: 'screen_orientation',
        onError: () {
          _screenOrientationStreamController!.add(ScreenOrientationEvent(0.0));
        },
      );
      _screenOrientationResultStream = _screenOrientationStreamController!.stream.asBroadcastStream();
      _screenOrientationStreamController!.onCancel = () {
        _screenOrientationStreamController!.close();
      };
    }

    return _screenOrientationResultStream;
  }
}