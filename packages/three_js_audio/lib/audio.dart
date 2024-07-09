import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:three_js_core/three_js_core.dart';

/// This utility class holds static references to some global audio objects.
///
/// You can use as a helper to very simply play a sound or a background music.
/// Alternatively you can create your own instances and control them yourself.
class Audio extends Object3D{
  bool autoplay = false;
  bool loop = false;
  bool hasPlaybackControl = true;
  bool isPlaying = false;
  AudioPlayer? source;
  Uint8List? _buffer;

  int loopEnd = 0;
  int loopStart = 0;
  double? duration;
  double playbackRate = 1;

  Timer? _delay;

  void setBuffer(Uint8List buffer){
    _buffer = buffer;
  }

  @override
  void dispose(){
    super.dispose();
    _delay?.cancel();
    source?.dispose();
  }

  /// Plays a single run of the given [file], with a given [volume].
  Future<void> play([int delay = 0]) async{
		if (isPlaying) {
			console.warning( 'Audio: Audio is already playing.' );
			return;
		}

		if(!hasPlaybackControl){
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

    isPlaying = true;

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
    await src.setReleaseMode(loop?ReleaseMode.loop:ReleaseMode.stop);
    await src.setPlaybackRate(playbackRate);
    await src.play(
      BytesSource(_buffer!),
      volume: 1.0,
      mode: PlayerMode.lowLatency,
      position: Duration(milliseconds: loopStart),
      balance: 0.0
    ).whenComplete((){
      isPlaying = false;
    });
    
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
    isPlaying = false;
    await source?.stop();
  }

  /// Resumes the currently played (but resumed) background music.
  Future<void> resume() async {
    isPlaying = true;
    await source?.resume().whenComplete((){
      isPlaying = false;
    });
  }

  /// Pauses the background music without unloading or resetting the audio
  /// player.
  Future<void> pause() async {
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if(isPlaying) {
      isPlaying = false;
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

		if (isPlaying) {
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

		if (isPlaying ) {
			await source?.setReleaseMode(loop?ReleaseMode.loop:ReleaseMode.stop);
		}
	}

	void setLoopStart(int value ) {
		loopStart = value;
	}

	void setLoopEnd(int value ) {
		loopEnd = value;
	}

	double? getVolume() {
		return source?.volume;
	}

	Future<void> setVolume(double value ) async{
		await source?.setVolume(value);
	}
}
