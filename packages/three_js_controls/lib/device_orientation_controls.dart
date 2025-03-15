import 'dart:math' as math;
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:three_js_sensors/three_js_sensors.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class DeviceOrientationControls{
  Camera object;
	double eps = 0.000001;
	bool enabled = true;
  ThreeJsSensors motionSensors = ThreeJsSensors();

  late GlobalKey<PeripheralsState> listenableKey;
	AbsoluteOrientationEvent _deviceOrientation = AbsoluteOrientationEvent(0,0,0);
	double screenOrientation = 0;
	double alphaOffset = 0; // radians

  DeviceOrientationControls(this.object, this.listenableKey):super(){
    connect();
    object.rotation.reorder(RotationOrders.yxz);
  }

	void onDeviceOrientationChangeEvent(AbsoluteOrientationEvent event ) {
		_deviceOrientation = event;
  }

	// The angles alpha, beta and gamma form a set of intrinsic Tait-Bryan angles of type Z-X'-Y''
  final _zee = Vector3( 0, 0, 1 );
  final _euler = Euler();
  final _q0 = Quaternion();
  final _q1 = Quaternion( - math.sqrt( 0.5 ), 0, 0, math.sqrt( 0.5 ) ); // - PI/2 around the x-axis

	void setObjectQuaternion(Quaternion quaternion, double alpha, double beta, double gamma, double orient ) {
    _euler.set( beta, alpha, - gamma, RotationOrders.xyz); // 'ZXY' for the device, but 'YXZ' for us
    quaternion.setFromEuler( _euler ); // orient the device
    quaternion.multiply( _q1 ); // camera looks out the back of the device, not the top
    quaternion.multiply( _q0.setFromAxisAngle( _zee, - orient ) ); // adjust for screen orientation
	}

	void connect(){
    motionSensors.screenOrientation(samplingPeriod: SensorInterval.gameInterval).listen(
      (ScreenOrientationEvent event) {
        if(event.angle != null){
          screenOrientation = event.angle!;
        }
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    );
    motionSensors.absoluteOrientation().listen(
      (AbsoluteOrientationEvent event) {
        onDeviceOrientationChangeEvent(event);
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    );
    
		enabled = true;
	}

	void disconnect() {
		enabled = false;
	}

  final _lastQuaternion = Quaternion();

	void update(){
    if (enabled == false ) return;

    final device = _deviceOrientation;

    final double alpha = device.yaw + alphaOffset; // Z
    final double beta = device.pitch; // X'
    final double gamma = device.roll; // Y''
    final double orient = screenOrientation > 0? screenOrientation.toRad(): 0; // O

    setObjectQuaternion( object.quaternion, alpha, beta, gamma, orient );

    if ( 8 * ( 1 - _lastQuaternion.dot(object.quaternion)) > eps ) {
      _lastQuaternion.setFrom(object.quaternion);
    }
	}

	void dispose(){}
}
