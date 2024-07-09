import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'audio_context.dart';

final _position = Vector3.zero();
final _quaternion = Quaternion.identity();
final _scale = Vector3.zero();
final _orientation = Vector3.zero();

class AudioListener extends Object3D {
  final Clock _clock = Clock();
  late AudioContext context;
  double timeDelta = 0;

	AudioListener():super(){
		context = AC.getContext();
		this.gain = context.createGain();
		this.gain.connect( context.destination );
		this.filter = null;
	}

	getInput() {
		return this.gain;
	}

	removeFilter() {
		if ( this.filter != null ) {
			this.gain.disconnect( this.filter );
			this.filter.disconnect(context.destination );
			this.gain.connect(context.destination );
			this.filter = null;
		}

		return this;
	}

	getFilter() {
		return this.filter;
	}

	setFilter( value ) {
		if ( this.filter != null ) {
			this.gain.disconnect( this.filter );
			this.filter.disconnect(context.destination );
		} 
    else {
			this.gain.disconnect(context.destination );
		}

		this.filter = value;
		this.gain.connect( this.filter );
		this.filter.connect(context.destination );

		return this;
	}

	getMasterVolume() {
		return this.gain.gain.value;
	}

	setMasterVolume( value ) {
		this.gain.gain.setTargetAtTime( value, context.currentTime, 0.01 );
		return this;
	}

  @override
	void updateMatrixWorld([bool force = false]) {
		super.updateMatrixWorld( force );
		final listener = context.listener;
		final up = this.up;

		timeDelta = _clock.getDelta();

		matrixWorld.decompose( _position, _quaternion, _scale );

		_orientation.setValues( 0, 0, - 1 ).applyQuaternion( _quaternion );

		if ( listener.positionX ) {
			final endTime = context.currentTime + timeDelta;

			listener.positionX.linearRampToValueAtTime( _position.x, endTime );
			listener.positionY.linearRampToValueAtTime( _position.y, endTime );
			listener.positionZ.linearRampToValueAtTime( _position.z, endTime );
			listener.forwardX.linearRampToValueAtTime( _orientation.x, endTime );
			listener.forwardY.linearRampToValueAtTime( _orientation.y, endTime );
			listener.forwardZ.linearRampToValueAtTime( _orientation.z, endTime );
			listener.upX.linearRampToValueAtTime( up.x, endTime );
			listener.upY.linearRampToValueAtTime( up.y, endTime );
			listener.upZ.linearRampToValueAtTime( up.z, endTime );
		} 
    else {
			listener.setPosition( _position.x, _position.y, _position.z );
			listener.setOrientation( _orientation.x, _orientation.y, _orientation.z, up.x, up.y, up.z );
		}
	}
}
