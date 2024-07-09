import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'audio.dart';
import 'audio_listener.dart';

final _position = Vector3.zero();
final _quaternion = Quaternion.identity();
final _scale = Vector3.zero();
final _orientation = Vector3.zero();

class PositionalAudio extends Audio {

	PositionalAudio(AudioListener listener):super(listener) {
		this.panner = context.createPanner();
		this.panner.panningModel = 'HRTF';
		this.panner.connect(gain);
	}

	getOutput() {
		return this.panner;
	}

	getRefDistance() {
		return this.panner.refDistance;
	}

	PositionalAudio setRefDistance( value ) {
		this.panner.refDistance = value;
		return this;
	}

	getRolloffFactor() {
		return this.panner.rolloffFactor;
	}

	PositionalAudio setRolloffFactor( value ) {
		this.panner.rolloffFactor = value;
		return this;
	}

	getDistanceModel() {
		return this.panner.distanceModel;
	}

	setDistanceModel( value ) {
		this.panner.distanceModel = value;
		return this;
	}

	getMaxDistance() {
		return this.panner.maxDistance;
	}

	PositionalAudio setMaxDistance( value ) {
		this.panner.maxDistance = value;
		return this;
	}

	PositionalAudio setDirectionalCone( coneInnerAngle, coneOuterAngle, coneOuterGain ) {
		this.panner.coneInnerAngle = coneInnerAngle;
		this.panner.coneOuterAngle = coneOuterAngle;
		this.panner.coneOuterGain = coneOuterGain;
		return this;
	}

  @override
	void updateMatrixWorld([bool force = false]) {
		super.updateMatrixWorld( force );

		if (hasPlaybackControl && !isPlaying) return;

		matrixWorld.decompose( _position, _quaternion, _scale );

		_orientation.setValues( 0, 0, 1 ).applyQuaternion( _quaternion );

		final panner = this.panner;

		if ( panner.positionX ) {
			final endTime = context.currentTime + listener.timeDelta;

			panner.positionX.linearRampToValueAtTime( _position.x, endTime );
			panner.positionY.linearRampToValueAtTime( _position.y, endTime );
			panner.positionZ.linearRampToValueAtTime( _position.z, endTime );
			panner.orientationX.linearRampToValueAtTime( _orientation.x, endTime );
			panner.orientationY.linearRampToValueAtTime( _orientation.y, endTime );
			panner.orientationZ.linearRampToValueAtTime( _orientation.z, endTime );
		} 
    else {
			panner.setPosition( _position.x, _position.y, _position.z );
			panner.setOrientation( _orientation.x, _orientation.y, _orientation.z );
		}
	}
}
