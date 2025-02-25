import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:three_js_core/three_js_core.dart';

/// This utility class holds static references to some global audio objects.
///
/// You can use as a helper to very simply play a sound or a background music.
/// Alternatively you can create your own instances and control them yourself.
class Audio extends Object3D{
  bool autoplay;
  bool loop;
  bool hasPlaybackControl;
  bool _isPlaying = false;

  AudioPlayer? source;
  //Uint8List? _buffer;

  int loopEnd = 0;
  int loopStart = 0;
  //double? duration;
  double playbackRate;

  late double _volume;
  late double _balance;

  Timer? _delay;
  bool get isPlaying => _isPlaying;

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
    source?.dispose();
    super.dispose();
  }

  /// Plays a single run of the given [file], with a given [volume].
  Future<void> play([int delay = 0]) async{
		if (_isPlaying) {
			console.warning( 'Audio: Audio is already playing.' );
			return;
		}

		if(!hasPlaybackControl){
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

    _isPlaying = true;

    if(source == null){
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
    final src = AudioPlayer();
    src.onPlayerComplete.listen((event) {
      _isPlaying = false;
    });
    //await src.setReleaseMode(loop?ReleaseMode.loop:ReleaseMode.stop);
    //await src.setPlaybackRate(playbackRate);
    await src.play(
      AssetSource(path),
      volume: _volume,
      mode: PlayerMode.lowLatency,
      position: Duration(milliseconds: loopStart),
      balance: _balance
    );
    
    source = src;
  }

  /// Stops the currently playing background music track (if any).
  Future<void> stop() async {
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

    _delay?.cancel();
    _delay = null;
    _isPlaying = false;
    await source?.stop();
  }

  /// Resumes the currently played (but resumed) background music.
  Future<void> resume() async {
    _isPlaying = true;
    await source?.resume();
  }

  /// Pauses the background music without unloading or resetting the audio
  /// player.
  Future<void> pause() async {
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if(_isPlaying) {
      _isPlaying = false;
      await source?.pause();
    }

    _delay?.cancel();
    _delay = null;
  }

	double? getPlaybackRate() {
		return source?.playbackRate;
	}

	Future<void>? setPlaybackRate(double value) async{
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if (_isPlaying) {
      playbackRate = value;
			await source?.setPlaybackRate(value);
		}
	}

	bool getLoop() {
		if (!hasPlaybackControl ) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return false;
		}

		return source?.releaseMode == ReleaseMode.loop;
	}

	Future<void> setLoop( value ) async{
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		loop = value;

		if (_isPlaying ) {
			await source?.setReleaseMode(loop?ReleaseMode.loop:ReleaseMode.stop);
		}
	}

	void setLoopStart(int value ) {
		loopStart = value;
	}

	void setLoopEnd(int value ) {
		loopEnd = value;
	}

	double? getBalance() {
		return source?.balance;
	}

	Future<void> setBalance(double value ) async{
    _balance = value;
		await source?.setBalance(value);
	}

	double? getVolume() {
		return source?.volume;
	}

	Future<void> setVolume(double value ) async{
    _volume = value;
		await source?.setVolume(value);
	}
}
