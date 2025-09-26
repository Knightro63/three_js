import 'dart:async';
import 'dart:math' as math;
import 'package:three_js_sensors/three_js_sensors.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class HeadPose{
	final double _eps = 0.000001;
	bool enabled = true;
  final _lastQuaternion = Quaternion();
  final Vector3 _deviceOrientation = Vector3();
  final ThreeJsSensors _motionSensors = ThreeJsSensors();
  late final StreamSubscription<AbsoluteOrientationEvent> _subscription;

  HeadPose():super(){
    _connect();
  }

	// The angles alpha, beta and gamma form a set of intrinsic Tait-Bryan angles of type Z-X'-Y''
  final _zee = Vector3( 0, 0, 1 );
  final _euler = Euler();
  final _orient = math.pi/2;
  final _q0 = Quaternion();
  final _q1 = Quaternion( - math.sqrt( 0.5 ), 0, 0, math.sqrt( 0.5 ) ); // - PI/2 around the x-axis

	void _setQuaternion(Quaternion quaternion, double alpha, double beta, double gamma) {
    _euler.set( beta, alpha, - gamma, RotationOrders.xyz); // 'ZXY' for the device, but 'YXZ' for us
    quaternion.setFromEuler( _euler ); // orient the device
    quaternion.multiply( _q1 ); // camera looks out the back of the device, not the top
    quaternion.multiply( _q0.setFromAxisAngle( _zee, - _orient ) ); // adjust for screen orientation
	}

	void _connect(){
    _subscription = _motionSensors.absoluteOrientation().listen(
      (AbsoluteOrientationEvent event) {
        _deviceOrientation.setValues(event.yaw, event.pitch, event.roll);
      },
      onError: (error) {},
      cancelOnError: true,
    );
    
		enabled = true;
	}

	void disconnect() {
		enabled = false;
	}

	void update(Camera camera){
    if (!enabled) return;

    _setQuaternion( camera.quaternion, _deviceOrientation.x, _deviceOrientation.y, _deviceOrientation.z );
    if ( 8 * ( 1 - _lastQuaternion.dot(camera.quaternion)) > _eps ) {
      _lastQuaternion.setFrom(camera.quaternion);
    }
	}

	void dispose(){
    enabled = false;
    _subscription.cancel();
  }
}
