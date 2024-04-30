part of three_js_controls;

/**
 * W3C Device Orientation control (http://w3c.github.io/deviceorientation/spec-source-orientation.html)
 */

class _DeviceOrientation{
  _DeviceOrientation({
    this.alpha = 0,
    this.beta = 0,
    this.gamma = 0
  });
  double alpha;
  double gamma;
  double beta;
}

class DeviceOrientationControls{
  late GlobalKey<PeripheralsState> listenableKey;
  PeripheralsState get domElement => listenableKey.currentState!;
  Camera object;

  DeviceOrientationControls(this.object, this.listenableKey ):super(){
    connect();
    object.rotation.reorder(RotationOrders.yxz);
  }

	//var changeEvent = { type: 'change' };
	double eps = 0.000001;
	bool enabled = true;

	_DeviceOrientation deviceOrientation = _DeviceOrientation();
	double screenOrientation = 0;
	double alphaOffset = 0; // radians

	void onDeviceOrientationChangeEvent( event ) {
		deviceOrientation = event;
	}

	void onScreenOrientationChangeEvent() {
		//screenOrientation = window.orientation ?? 0;
	}

	// The angles alpha, beta and gamma form a set of intrinsic Tait-Bryan angles of type Z-X'-Y''
  final _zee = Vector3( 0, 0, 1 );
  final _euler = Euler();
  final _q0 = Quaternion();
  final _q1 = Quaternion( - math.sqrt( 0.5 ), 0, 0, math.sqrt( 0.5 ) ); // - PI/2 around the x-axis

	void setObjectQuaternion(Quaternion quaternion, double alpha, double beta, double gamma, double orient ) {
    _euler.set( beta, alpha, - gamma,RotationOrders.yxz); // 'ZXY' for the device, but 'YXZ' for us
    quaternion.setFromEuler( _euler ); // orient the device
    quaternion.multiply( _q1 ); // camera looks out the back of the device, not the top
    quaternion.multiply( _q0.setFromAxisAngle( _zee, - orient ) ); // adjust for screen orientation
	}

	void connect(){
		onScreenOrientationChangeEvent(); // run once on load
    domElement.addEventListener( PeripheralType.orientationchange, onScreenOrientationChangeEvent, false );
    domElement.addEventListener( PeripheralType.deviceorientation, onDeviceOrientationChangeEvent, false );
		enabled = true;
	}

	void disconnect() {
		domElement.removeEventListener( PeripheralType.orientationchange, onScreenOrientationChangeEvent, false );
		domElement.removeEventListener( PeripheralType.deviceorientation, onDeviceOrientationChangeEvent, false );
		enabled = false;
	}

  final _lastQuaternion = Quaternion();

	void update(){
    if (enabled == false ) return;

    final device = deviceOrientation;

    final double alpha = device.alpha > 0? device.alpha.toRad() + alphaOffset : 0; // Z
    final double beta = device.beta > 0? device.beta.toRad() : 0; // X'
    final double gamma = device.gamma > 0? device.gamma.toRad() : 0; // Y''
    final double orient = screenOrientation > 0? screenOrientation.toRad(): 0; // O

    setObjectQuaternion( object.quaternion, alpha, beta, gamma, orient );
    if ( 8 * ( 1 - _lastQuaternion.dot(object.quaternion)) > eps ) {
      _lastQuaternion.setFrom(object.quaternion);
      //dispatchEvent( changeEvent );
    }
	}

	void dispose(){
	  disconnect();
	}
}
