import 'dart:async';
import 'package:three_js_audio/three_js_audio.dart';
import 'package:three_js_core/three_js_core.dart';

/// This utility class holds static references to some global audio objects.
///
/// You can use as a helper to very simply play a sound or a background music.
/// Alternatively you can create your own instances and control them yourself.
class Audio extends Object3D{
  bool autoplay;
  bool loop;
  bool hasPlaybackControl;

  SoundHandle? source;
  AudioSource? _audioSource;
  
  //Uint8List? _buffer;

  int loopEnd = 0;
  int loopStart = 0;
  //double? duration;
  double playbackRate;

  late double _volume;
  late double _balance;
  AudioLoader _loader = AudioLoader();

  Timer? _delay;
  bool get isPlaying => source != null?soloud!.getPause(source!):false;
  bool _hasStarted = false;

  String path;

  Audio({
    required this.path,
    double balance = 0.0,
    double volume = 1.0,
    this.playbackRate = 1.0,
    this.hasPlaybackControl = true,
    this.autoplay = false,
    this.loop = false
  }){
    _balance = balance;
    _volume = volume;

    if(autoplay){
      play();
    }
  }

  // void setBuffer(Uint8List buffer){
  //   _buffer = buffer;
  // }

  @override
  void dispose(){
    _delay?.cancel();
    soloud?.deinit();
    super.dispose();
  }

  /// Plays a single run of the given [file], with a given [volume].
  Future<void> play([int delay = 0]) async{
		if (_hasStarted && isPlaying) {
			console.warning( 'Audio: Audio is already playing.' );
			return;
		}

    _hasStarted = true;

		if(!hasPlaybackControl){
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

    if(source == null){
      soloud = SoLoud.instance;
      await soloud?.init();

      if(delay != 0){
        _delay = Timer(Duration(milliseconds: delay), (){
          _play();
          _delay?.cancel();
          _delay = null;
        });
      }
      else{
        _play();
      }
    }
    else{
      resume();
    }
  }

  /// Plays a single run of the given [file], with a given [volume].
  Future<void> _play() async{
    _loader.unknown(path);
    _audioSource = await _loader.unknown(path);

    source = _audioSource == null?null: await soloud?.play(
      _audioSource!,
      volume: _volume,
      loopingStartAt: Duration(milliseconds: loopStart),
      looping: loop
    );

    setBalance(_balance);
  }

  /// Stops the currently playing background music track (if any).
  Future<void> stop() async {
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

    _delay?.cancel();
    _delay = null;
    if(source != null)await soloud?.stop(source!);
  }

  /// Resumes the currently played (but resumed) background music.
  Future<void> resume() async {
    if(source != null){
      final pos = soloud!.getPosition(source!);
      if(pos.inMilliseconds == 0){
        soloud?.play(_audioSource!);
      }
      else{
        soloud?.setPause(source!, false);
      }
    }
  }

  /// Pauses the background music without unloading or resetting the audio
  /// player.
  Future<void> pause() async {
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if(isPlaying) {
      if(source != null)soloud?.setPause(source!, true);
    }

    _delay?.cancel();
    _delay = null;
  }

	double? getPlaybackRate() {
		return source == null?null:soloud?.getRelativePlaySpeed(source!);
	}

	void setPlaybackRate(double value){
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if (isPlaying) {
      playbackRate = value;
			source == null?null:soloud?.setRelativePlaySpeed(source!,value);
		}
	}

	bool getLoop() {
		if (!hasPlaybackControl ) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return false;
		}

		return source == null?false:soloud!.getLooping(source!);
	}

	void setLoop(bool value ){
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		loop = value;

		if (isPlaying ) {
			if(source != null) soloud?.setLooping(source!, value);
		}
	}

	void setLoopStart(int value ) {
		loopStart = value;
	}

	void setLoopEnd(int value ) {
		loopEnd = value;
	}

	double? getBalance() {
		return source != null?soloud?.getPan(source!):0;
	}

	void setBalance(double value ){
    _balance = value;
		if(source != null)soloud?.setPan(source!,value);
	}

	double? getVolume() {
		return source == null? 0:soloud?.getVolume(source!);
	}

	void setVolume(double value ){
    _volume = value;
    if(source != null) soloud?.setVolume(source!,value);
	}
}
