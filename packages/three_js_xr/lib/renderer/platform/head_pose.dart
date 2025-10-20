import 'dart:async';
import 'dart:math' as math;
import 'package:three_js_sensors/three_js_sensors.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class HeadPose{
	final double _eps = 0.000001;
	bool enabled = true;
  final _lastQuaternion = Quaternion();
  final Quaternion _deviceOrientation = Quaternion();
  final ThreeJsSensors _motionSensors = ThreeJsSensors();
  late final StreamSubscription<AbsoluteOrientationEvent> _subscription;

  HeadPose():super(){
    _connect();
  }

	// The angles alpha, beta and gamma form a set of intrinsic Tait-Bryan angles of type Z-X'-Y''
  final _orient = math.pi/2;

	void _setQuaternion(Quaternion quaternion, Quaternion sensor){ {
    final sensorQuaternion = Quaternion().setFrom(sensor);
    final correctionQuaternion = Quaternion().setFromAxisAngle(
      Vector3(1,0,0),
      -_orient
    );
    quaternion.multiplyQuaternions(correctionQuaternion, sensorQuaternion);
    }
	}

	void _connect(){
    _subscription = _motionSensors.absoluteOrientation().listen(
      (AbsoluteOrientationEvent event) {
        _deviceOrientation.fromArray(event.quantFromAxis(QuaternionOrientation.yxzw, [-1,1,1,1]));
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

    _setQuaternion( camera.quaternion, _deviceOrientation);
    if ( 8 * ( 1 - _lastQuaternion.dot(camera.quaternion)) > _eps ) {
      _lastQuaternion.setFrom(camera.quaternion);
    }
	}

	void dispose(){
    enabled = false;
    _subscription.cancel();
  }
}
