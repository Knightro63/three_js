enum QuaternionOrientation{xyzw, wxyz, yzwx, zwxy, wzyx, yxzw, zxyw, xwyz, wyzx, zxwy}

// from https://github.com/flutter/plugins/tree/master/packages/sensors
/// Discrete reading from an accelerometer. Accelerometers measure the velocity
/// of the device. Note that these readings include the effects of gravity. Put
/// simply, you can use accelerometer readings to tell if the device is moving in
/// a particular direction.
class AccelerometerEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  AccelerometerEvent(this.x, this.y, this.z){_init();}
  AccelerometerEvent.fromList(List<double> list): x = list[0],y = list[1],z = list[2]{_init();}
  
  void _init(){
    final now = DateTime.now();
    final stopwatch = Stopwatch()..start();
    // Get the nanosecond part (the extra precision beyond microseconds)
    // This value is relative to when the stopwatch was started.
    // In a real-world scenario, you would obtain this from a high-resolution source.
    final extraNanos = stopwatch.elapsedTicks % 1000;
    stopwatch.stop();
    timeStampNS = (now.microsecondsSinceEpoch * 1000) + extraNanos;
    timeStamp = now.millisecondsSinceEpoch;
  }

  late final int timeStamp;
  late final int timeStampNS;
  
  late List<double> data = [x,y,z];

  /// Acceleration force along the x axis (including gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving to the right and negative mean it is moving to the left.
  final double x;

  /// Acceleration force along the y axis (including gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving towards the sky and negative mean it is moving towards
  /// the ground.
  final double y;

  /// Acceleration force along the z axis (including gravity) measured in m/s^2.
  ///
  /// This uses a right-handed coordinate system. So when the device is held
  /// upright and facing the user, positive values mean the device is moving
  /// towards the user and negative mean it is moving away from them.
  final double z;

  @override
  String toString() => '[AccelerometerEvent (x: $x, y: $y, z: $z)]';
}

class MagnetometerEvent {
  MagnetometerEvent(this.x, this.y, this.z){_init();}
  MagnetometerEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2]{_init();}
  void _init(){
    final now = DateTime.now();
    final stopwatch = Stopwatch()..start();
    // Get the nanosecond part (the extra precision beyond microseconds)
    // This value is relative to when the stopwatch was started.
    // In a real-world scenario, you would obtain this from a high-resolution source.
    final extraNanos = stopwatch.elapsedTicks % 1000;
    stopwatch.stop();
    timeStampNS = (now.microsecondsSinceEpoch * 1000) + extraNanos;
    timeStamp = now.millisecondsSinceEpoch;
  }

  late final int timeStamp;
  late final int timeStampNS;

  final double x;
  final double y;
  final double z;
  late List<double> data = [x,y,z];
  @override
  String toString() => '[Magnetometer (x: $x, y: $y, z: $z)]';
}

/// Discrete reading from a gyroscope. Gyroscopes measure the rate or rotation of
/// the device in 3D space.
class GyroscopeEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  GyroscopeEvent(this.x, this.y, this.z){_init();}
  GyroscopeEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2]{_init();}
  void _init(){
    final now = DateTime.now();
    final stopwatch = Stopwatch()..start();
    // Get the nanosecond part (the extra precision beyond microseconds)
    // This value is relative to when the stopwatch was started.
    // In a real-world scenario, you would obtain this from a high-resolution source.
    final extraNanos = stopwatch.elapsedTicks % 1000;
    stopwatch.stop();
    timeStampNS = (now.microsecondsSinceEpoch * 1000) + extraNanos;
    timeStamp = now.millisecondsSinceEpoch;
  }

  late final int timeStamp;
  late final int timeStampNS;

  /// Rate of rotation around the x axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "pitch". The top of the device will tilt towards or away from the
  /// user as this value changes.
  final double x;

  /// Rate of rotation around the y axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "yaw". The lengthwise edge of the device will rotate towards or away from
  /// the user as this value changes.
  final double y;

  /// Rate of rotation around the z axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "roll". When this changes the face of the device should remain facing
  /// forward, but the orientation will change from portrait to landscape and so
  /// on.
  final double z;

  late List<double> data = [x,y,z];

  @override
  String toString() => '[GyroscopeEvent (x: $x, y: $y, z: $z)]';
}

/// Like [AccelerometerEvent], this is a discrete reading from an accelerometer
/// and measures the velocity of the device. However, unlike
/// [AccelerometerEvent], this event does not include the effects of gravity.
class UserAccelerometerEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  UserAccelerometerEvent(this.x, this.y, this.z){_init();}
  UserAccelerometerEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2]{_init();}
  void _init(){
    final now = DateTime.now();
    final stopwatch = Stopwatch()..start();
    // Get the nanosecond part (the extra precision beyond microseconds)
    // This value is relative to when the stopwatch was started.
    // In a real-world scenario, you would obtain this from a high-resolution source.
    final extraNanos = stopwatch.elapsedTicks % 1000;
    stopwatch.stop();
    timeStampNS = (now.microsecondsSinceEpoch * 1000) + extraNanos;
    timeStamp = now.millisecondsSinceEpoch;
  }

  late final int timeStamp;
  late final int timeStampNS;

  /// Acceleration force along the x axis (excluding gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving to the right and negative mean it is moving to the left.
  final double x;

  /// Acceleration force along the y axis (excluding gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving towards the sky and negative mean it is moving towards
  /// the ground.
  final double y;

  /// Acceleration force along the z axis (excluding gravity) measured in m/s^2.
  ///
  /// This uses a right-handed coordinate system. So when the device is held
  /// upright and facing the user, positive values mean the device is moving
  /// towards the user and negative mean it is moving away from them.
  final double z;

  late List<double> data = [x,y,z];
  
  @override
  String toString() => '[UserAccelerometerEvent (x: $x, y: $y, z: $z)]';
}

class AbsoluteOrientationEvent {
  AbsoluteOrientationEvent([this.yaw = 0, this.pitch = 0, this.roll = 0, this.x = 0, this.y = 0, this.z = 0, this.w = 0]){_init();}
  AbsoluteOrientationEvent.fromList(List<double> list)
      : yaw = list[0],
        pitch = list[1],
        roll = list[2],
        x = list[3],
        y = list[4],
        z = list[5],
        w = list[6]{_init();}
  void _init(){
    final now = DateTime.now();
    final stopwatch = Stopwatch()..start();
    // Get the nanosecond part (the extra precision beyond microseconds)
    // This value is relative to when the stopwatch was started.
    // In a real-world scenario, you would obtain this from a high-resolution source.
    final extraNanos = stopwatch.elapsedTicks % 1000;
    stopwatch.stop();
    timeStampNS = (now.microsecondsSinceEpoch * 1000) + extraNanos;
    timeStamp = now.millisecondsSinceEpoch;
  }

  late final int timeStamp;
  late final int timeStampNS;

  /// The yaw of the device in radians.
  final double yaw;
  /// The pitch of the device in radians.
  final double pitch;
  /// The roll of the device in radians.
  final double roll;

  final double x;
  final double y;
  final double z;
  final double w;
  List<double> get quaternion => [x,y,z,w];
  List<double> get eulerAngles => [yaw,pitch,roll];

  List<double> quantFromAxis(QuaternionOrientation orientation, [List<double>? multiply]){
    multiply ??= [1,1,1,1];
    switch (orientation) {
      case QuaternionOrientation.xyzw:
        return [x*multiply[0],y*multiply[1],z*multiply[2],w*multiply[3]];
      case QuaternionOrientation.wxyz:
        return [w*multiply[3],x*multiply[0],y*multiply[1],z*multiply[2]];
      case QuaternionOrientation.yzwx:
        return [y*multiply[1],z*multiply[2],w*multiply[3],x*multiply[0]];
      case QuaternionOrientation.zwxy:
        return [z*multiply[2],w*multiply[3],x*multiply[0],y*multiply[1]];
      case QuaternionOrientation.wzyx:
        return [w*multiply[3],z*multiply[2],y*multiply[1],x*multiply[0]];
      case QuaternionOrientation.yxzw:
        return [y*multiply[1],x*multiply[0],z*multiply[2],w*multiply[3]];
      case QuaternionOrientation.zxyw:    
        return [z*multiply[2],x*multiply[0],y*multiply[1],w*multiply[3]];
      case QuaternionOrientation.xwyz:
        return [x*multiply[0],w*multiply[3],y*multiply[1],z*multiply[2]];
      case QuaternionOrientation.wyzx:
        return [w*multiply[3],y*multiply[1],z*multiply[2],x*multiply[0]];
      case QuaternionOrientation.zxwy:
        return [z*multiply[2],x*multiply[0],w*multiply[3],y*multiply[1]];
    }
  }

  @override
  String toString() => '[Orientation (yaw: $yaw, pitch: $pitch, roll: $roll, x: $x, y: $y, z: $z, w: $w)]';
}

class ScreenOrientationEvent {
  ScreenOrientationEvent(this.angle){_init();}
  void _init(){
    final now = DateTime.now();
    final stopwatch = Stopwatch()..start();
    // Get the nanosecond part (the extra precision beyond microseconds)
    // This value is relative to when the stopwatch was started.
    // In a real-world scenario, you would obtain this from a high-resolution source.
    final extraNanos = stopwatch.elapsedTicks % 1000;
    stopwatch.stop();
    timeStampNS = (now.microsecondsSinceEpoch * 1000) + extraNanos;
    timeStamp = now.millisecondsSinceEpoch;
  }

  late final int timeStamp;
  late final int timeStampNS;

  /// The screen's current orientation angle. The angle may be 0, 90, 180, -90 degrees
  final double? angle;

  @override
  String toString() => '[ScreenOrientation (angle: $angle)]';
}

enum SensorType{
  accelerometer,
  magnetometer,
  gyroscope,
  userAccelerometer,
  orientation,
  absoluteOrientation,
}

extension DF on Duration {
  /// Converts the duration to a frequency in Hz.
  int get frequency {
    if (inMicroseconds <= 10) {
      return 100;
    }
    
    return 1000 ~/ inMilliseconds;
  }
}

class SensorInterval {
  static const normalInterval = Duration(milliseconds: 200);
  static const uiInterval = Duration(milliseconds: 66, microseconds: 667);
  static const gameInterval = Duration(milliseconds: 20);
  static const fastestInterval = Duration.zero;
}