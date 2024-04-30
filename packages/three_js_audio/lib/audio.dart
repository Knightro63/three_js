import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_analyser.dart';
import 'audio_context.dart';
import 'audio_listener.dart';

class Audio extends Object3D {
  AudioListener listener;
  late AudioContext context;
  late GainNode gain;

  bool autoplay = false;
  bool loop = false;
  bool isPlaying = false;
  bool hasPlaybackControl = true;
  bool _connected = false;

  String sourceType = 'empty';
  AudioPlayer? source;
  AudioBuffer? buffer;

  int loopEnd = 0;
  int loopStart = 0;
  offset = 0;
  detune = 0;
  double? duration;
  double playbackRate = 1;

  _startedAt = 0;
  double _progress = 0;
  filters = [];

	Audio(this.listener ):super(){
		context = listener.context;
		gain = context.createGain();
		gain.connect(listener.getInput());
	}

	NodeType getOutput() {
		return gain;
	}

	Audio setNodeSource(AudioBufferSourceNode audioNode ) {
		hasPlaybackControl = false;
		sourceType = 'audioNode';
		source = audioNode;
		connect();
		return this;
	}

	Audio setMediaElementSource( mediaElement ) {
		hasPlaybackControl = false;
		sourceType = 'mediaNode';
		source = context.createMediaElementSource( mediaElement );
		connect();

		return this;
	}

	Audio setMediaStreamSource(MediaStream mediaStream ) {
		hasPlaybackControl = false;
		sourceType = 'mediaStreamNode';
		source = context.createMediaStreamSource( mediaStream );
		connect();

		return this;
	}

	Audio setBuffer( audioBuffer ) {
		buffer = audioBuffer;
		sourceType = 'buffer';

		if (autoplay) play();

		return this;
	}

	play([delay = 0]) {
		if (isPlaying) {
			print( 'THREE.Audio: Audio is already playing.' );
			return;
		}

		if(!hasPlaybackControl){
			print( 'THREE.Audio: this Audio has no playback control.' );
			return;
		}

		_startedAt = context.currentTime + delay;

		final source = context.createBufferSource();
		source.buffer = buffer;
		source.loop = loop;
		source.loopStart = loopStart;
		source.loopEnd = loopEnd;
		source.onended = onEnded.bind( this );
		source.start(_startedAt, _progress + offset, duration );

		isPlaying = true;

		this.source = source;

		setDetune(detune );
		setPlaybackRate(playbackRate );

		return connect();
	}

	pause() {
		if (!hasPlaybackControl) {
			print( 'THREE.Audio: this Audio has no playback control.' );
			return;
		}

		if(isPlaying) {
			// update current progress
			_progress += math.max(context.currentTime - _startedAt, 0 ) * playbackRate;

			if (loop) {
				// ensure _progress does not exceed duration with looped audios
				_progress = _progress % (duration ?? buffer.duration);
			}

			source.stop();
			source.onended = null;

			isPlaying = false;
		}

		return this;
	}

	Audio? stop() {
		if (!hasPlaybackControl) {
			print( 'THREE.Audio: this Audio has no playback control.' );
			return null;
		}

		_progress = 0;

		source.stop();
		source.onended = null;
		isPlaying = false;

		return this;
	}

	Audio connect() {
		if (filters.isNotEmpty) {
			source.connect(filters[ 0 ] );

			for (int i = 1, l = filters.length; i < l; i ++ ) {
				filters[ i - 1 ].connect(filters[ i ] );
			}

			filters[filters.length - 1 ].connect(getOutput() );
		} 
    else {
			source.connect(getOutput() );
		}

		_connected = true;

		return this;
	}

	Audio disconnect() {
		if (filters.isNotEmpty ) {
			source.disconnect(filters[ 0 ] );

			for (int i = 1, l = filters.length; i < l; i ++ ) {
				filters[ i - 1 ].disconnect(filters[ i ] );
			}

			filters[filters.length - 1 ].disconnect(getOutput() );
		} 
    else {
			source.disconnect(getOutput() );
		}

		_connected = false;

		return this;
	}

	getFilters() {
		return filters;
	}

	setFilters( value ) {
		if ( ! value ) value = [];
		if (_connected) {
			disconnect();
			filters = value.slice();
			connect();
		} 
    else {
			filters = value.slice();
		}

		return this;
	}

	setDetune( value ) {
		detune = value;

		if (source.detune == null ) return; // only set detune when available
		if (isPlaying) {
			source.detune.setTargetAtTime(detune, context.currentTime, 0.01 );
		}

		return this;
	}

	getDetune() {
		return detune;
	}

	getFilter() {
		return getFilters()[ 0 ];
	}

	setFilter( filter ) {
		return setFilters( filter ? [ filter ] : [] );
	}

	Audio? setPlaybackRate( value ) {
		if (!hasPlaybackControl) {
			print( 'THREE.Audio: this Audio has no playback control.' );
			return null;
		}

		playbackRate = value;

		if (isPlaying) {
			source?.playbackRate.setTargetAtTime(playbackRate, context.currentTime, 0.01 );
		}

		return this;
	}

	getPlaybackRate() {
		return playbackRate;
	}

	void onEnded() {
		isPlaying = false;
	}

	bool getLoop() {
		if (!hasPlaybackControl ) {
			print( 'THREE.Audio: this Audio has no playback control.' );
			return false;
		}

		return loop;
	}

	setLoop( value ) {
		if (!hasPlaybackControl) {
			print( 'THREE.Audio: this Audio has no playback control.' );
			return;
		}

		loop = value;

		if (isPlaying ) {
			source.loop = loop;
		}

		return this;
	}

	Audio setLoopStart(int value ) {
		loopStart = value;
		return this;
	}

	Audio setLoopEnd(int value ) {
		loopEnd = value;
		return this;
	}

	double getVolume() {
		return gain.gain.value;
	}

	Audio setVolume( value ) {
		gain.gain.setTargetAtTime( value, context.currentTime, 0.01 );
		return this;
	}
}
