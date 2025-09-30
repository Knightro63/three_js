import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:three_js_sensors/three_js_sensors.dart';
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThreeJsSensors motionSensors = ThreeJsSensors();
  final Vector3 _accelerometer = Vector3.zero();
  final Vector3 _gyroscope = Vector3.zero();
  final Vector3 _magnetometer = Vector3.zero();
  final Vector3 _userAaccelerometer = Vector3.zero();
  final Vector3 _orientation = Vector3.zero();
  final Quaternion _absoluteOrientation = Quaternion(0,0,0,1);
  final Vector3 _absoluteOrientation2 = Vector3.zero();
  double? _screenOrientation = 0;

  Matrix4 getRotationMatrix(Vector3 gravity, Vector3 geomagnetic) {
    Vector3 a = gravity.normalized();
    Vector3 e = geomagnetic.normalized();
    Vector3 h = e.cross(a).normalized();
    Vector3 m = a.cross(h).normalized();
    return Matrix4(
      h.x, m.x, a.x, 0, //
      h.y, m.y, a.y, 0,
      h.z, m.z, a.z, 0,
      0, 0, 0, 1,
    );
  }

  Vector3 getOrientation(Matrix4 m) {
    final r = m.storage;
    return Vector3(
      math.atan2(-r[4], r[5]),
      math.asin(r[6]),
      math.atan2(-r[2], r[10]),
    );
  }

  @override
  void initState() {
    super.initState();
    motionSensors.gyroscope().listen((GyroscopeEvent event) {
      setState(() {
        _gyroscope.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.accelerometer().listen((AccelerometerEvent event) {
      setState(() {
        _accelerometer.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.userAccelerometer().listen((UserAccelerometerEvent event) {
      setState(() {
        _userAaccelerometer.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.magnetometer().listen((MagnetometerEvent event) {
      setState(() {
        _magnetometer.setValues(event.x, event.y, event.z);
        var matrix = getRotationMatrix(_accelerometer, _magnetometer);
        _absoluteOrientation2.setFrom(getOrientation(matrix));
      });
    });
    motionSensors.absoluteOrientation().listen((AbsoluteOrientationEvent event) {
      setState(() {
        _absoluteOrientation.setValues(event.x, event.y, event.z, event.w);
      });
    });
    motionSensors.screenOrientation().listen((ScreenOrientationEvent event) {
      setState(() {
        _screenOrientation = event.angle;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Motion Sensors'),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Accelerometer'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_accelerometer.x.toStringAsFixed(4)),
                  Text(_accelerometer.y.toStringAsFixed(4)),
                  Text(_accelerometer.z.toStringAsFixed(4)),
                ],
              ),
              const Text('Magnetometer'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_magnetometer.x.toStringAsFixed(4)),
                  Text(_magnetometer.y.toStringAsFixed(4)),
                  Text(_magnetometer.z.toStringAsFixed(4)),
                ],
              ),
              const Text('Gyroscope'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_gyroscope.x.toStringAsFixed(4)),
                  Text(_gyroscope.y.toStringAsFixed(4)),
                  Text(_gyroscope.z.toStringAsFixed(4)),
                ],
              ),
              const Text('User Accelerometer'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_userAaccelerometer.x.toStringAsFixed(4)),
                  Text(_userAaccelerometer.y.toStringAsFixed(4)),
                  Text(_userAaccelerometer.z.toStringAsFixed(4)),
                ],
              ),
              const Text('Orientation'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(degrees(_orientation.x).toStringAsFixed(4)),
                  Text(degrees(_orientation.y).toStringAsFixed(4)),
                  Text(degrees(_orientation.z).toStringAsFixed(4)),
                ],
              ),
              const Text('Absolute Orientation'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(degrees(_absoluteOrientation.x).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation.y).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation.z).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation.w).toStringAsFixed(4)),
                ],
              ),
              const Text('Orientation (accelerometer + magnetometer)'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(degrees(_absoluteOrientation2.x).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation2.y).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation2.z).toStringAsFixed(4)),
                ],
              ),
              const Text('Screen Orientation'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_screenOrientation!.toStringAsFixed(4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}