import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:three_js_core/three_js_core.dart';

/// This utility class holds static references to some global audio objects.
///
/// You can use as a helper to very simply play a sound or a background music.
/// Alternatively you can create your own instances and control them yourself.
class FlutterAudio extends Audio{
  bool _isPlaying = false;
  AudioPlayer? source;
  late double _volume;
  late double _balance;
  Timer? _delay;
  @override
  bool get isPlaying => _isPlaying;

  FlutterAudio({
    required super.path,
    double balance = 0.0,
    double volume = 1.0,
    super.playbackRate = 1.0,
    super.hasPlaybackControl = true,
    super.autoplay = false,
    super.loop = false
  }){
    _balance = balance;
    _volume = volume;

    if(autoplay){
      play();
    }
  }

  @override
  void dispose(){
    _delay?.cancel();
    source?.dispose();
    super.dispose();
  }

  /// Plays a single run of the given [file], with a given [volume].
  @override
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
      replay();
    }
  }

  @override
  Future<void> replay() async{
    await source?.seek(Duration.zero);
    await source?.resume();
  }

  /// Plays a single run of the given [file], with a given [volume].
  Future<void> _play() async{
    final newPath = path.replaceAll('assets/', '');
    final src = AudioPlayer();
    src.onPlayerComplete.listen((event) {
      _isPlaying = false;
    });
    await src.setReleaseMode(loop?ReleaseMode.loop:ReleaseMode.stop);
    await src.setPlaybackRate(playbackRate);
    await src.play(
      AssetSource(newPath),
      volume: _volume,
      mode: PlayerMode.lowLatency,
      position: Duration(milliseconds: loopStart),
      balance: _balance
    );
    
    source = src;
  }

  /// Stops the currently playing background music track (if any).
  @override
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
  @override
  Future<void> resume() async {
    _isPlaying = true;
    await source?.resume();
  }

  /// Pauses the background music without unloading or resetting the audio
  /// player.
  @override
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

	@override
  double? getPlaybackRate() {
		return source?.playbackRate;
	}

	@override
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

	@override
  bool getLoop() {
		if (!hasPlaybackControl ) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return false;
		}

		return source?.releaseMode == ReleaseMode.loop;
	}

	@override
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

	@override
  void setLoopStart(int value ) {
		loopStart = value;
	}

	@override
  void setLoopEnd(int value ) {
		loopEnd = value;
	}

	@override
  double? getBalance() {
		return source?.balance;
	}

	@override
  Future<void> setBalance(double value ) async{
    _balance = value;
		await source?.setBalance(value);
	}

	@override
  double? getVolume() {
		return source?.volume;
	}

	@override
  Future<void> setVolume(double value ) async{
    _volume = value;
		await source?.setVolume(value);
	}
}