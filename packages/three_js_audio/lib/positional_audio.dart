import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'audio.dart';

final _position = Vector3.zero();
final _quaternion = Quaternion.identity();
final _scale = Vector3.zero();
final _orientation = Vector3.zero();

class PositionalAudio extends Audio {
  double refDistance = 0;
  double maxDistance = double.infinity;
  double rolloffFactor = 0;

  double coneInnerAngle = 0;
  double coneOuterAngle = 180;
  double coneOuterGain = 1;

  Object3D listner;

	PositionalAudio(this.listner);

	void setDirectionalCone(double coneInnerAngle, double coneOuterAngle, double coneOuterGain) {
		this.coneInnerAngle = coneInnerAngle;
		this.coneOuterAngle = coneOuterAngle;
		this.coneOuterGain = coneOuterGain;
	}

  void update(){
    print(position.distanceTo(listner.position));
  }

  @override
	void updateMatrixWorld([bool force = false]) {
		super.updateMatrixWorld( force );

		if (hasPlaybackControl && !isPlaying) return;

		matrixWorld.decompose( _position, _quaternion, _scale );
		_orientation.setValues( 0, 0, 1 ).applyQuaternion( _quaternion );

    print(position.distanceTo(listner.position));


		// if ( panner.positionX ) {
		// 	final endTime = context.currentTime + listener.timeDelta;

		// 	panner.positionX.linearRampToValueAtTime( _position.x, endTime );
		// 	panner.positionY.linearRampToValueAtTime( _position.y, endTime );
		// 	panner.positionZ.linearRampToValueAtTime( _position.z, endTime );
		// 	panner.orientationX.linearRampToValueAtTime( _orientation.x, endTime );
		// 	panner.orientationY.linearRampToValueAtTime( _orientation.y, endTime );
		// 	panner.orientationZ.linearRampToValueAtTime( _orientation.z, endTime );
		// } 
    // else {
		// 	panner.setPosition( _position.x, _position.y, _position.z );
		// 	panner.setOrientation( _orientation.x, _orientation.y, _orientation.z );
		// }
	}
}
