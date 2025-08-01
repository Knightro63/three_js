import 'dart:async';
import 'audio_latency_loader.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// This utility class holds static references to some global audio objects.
///
/// You can use as a helper to very simply play a sound or a background music.
/// Alternatively you can create your own instances and control them yourself.
class AudioLatency extends Audio{
  SoundHandle? source;
  AudioSource? _audioSource;
  late double _volume;
  late double _balance;
  AudioLatencyLoader _loader = AudioLatencyLoader();

  Timer? _delay;
  bool get isPlaying => source != null?!SoLoud.instance.getPause(source!):false;
  bool _hasStarted = false;

  AudioLatency({
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

    // WidgetsFlutterBinding.ensureInitialized();

    // if(_didInit == 0){
    //   _didInit++;
    //   SoLoud.instance.init().then((_) async{
    //     _play();
    //   });
    // }
    // else{
      _play();
    //}
  }

  static Future<void> initSource() async{
    await SoLoud.instance.init();
  }
  static void deinitSource(){
    SoLoud.instance.deinit();
  }

  Future<void> _play() async{
    _loader.unknown(path);
    _audioSource = await _loader.unknown(path);

    source = _audioSource == null?null: await SoLoud.instance.play(
      _audioSource!,
      volume: _volume,
      loopingStartAt: Duration(milliseconds: loopStart),
      looping: loop
    );
    setBalance(_balance);
    setPlaybackRate(playbackRate);
  }

  @override
  void dispose(){
    _delay?.cancel();
    super.dispose();
  }

  /// Plays a single run of the given [file], with a given [volume].
  @override
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
    if(delay == 0){
      replay();
    }
    else{
      Future.delayed(Duration(milliseconds: delay),replay);
    }
  }
  @override
  Future<void> replay() async{
    if(source != null){
      //SoLoud.instance.seek(source!,Duration.zero);
      await SoLoud.instance.play(
        _audioSource!,
        volume: _volume,
        looping: loop,
        loopingStartAt: Duration(milliseconds: loopStart),
      );
    }
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
    if(source != null)await SoLoud.instance.stop(source!);
  }

  /// Resumes the currently played (but resumed) background music.
  @override
  Future<void> resume() async {
    await SoLoud.instance.play(
      _audioSource!,
      volume: _volume,
      looping: loop,
      loopingStartAt: Duration(milliseconds: loopStart),
    );
    // if(source != null){
    //   final pos = SoLoud.instance.getPosition(source!);
    //   if(pos.inMilliseconds == 0){
        
    //   }
    //   else{
    //     SoLoud.instance.setPause(source!, false);
    //   }
    // }
  }

  /// Pauses the background music without unloading or resetting the audio
  /// player.
  @override
  Future<void> pause() async {
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if(isPlaying) {
      if(source != null)SoLoud.instance.setPause(source!, true);
    }

    _delay?.cancel();
    _delay = null;
  }

	@override
  double? getPlaybackRate() {
		return source == null?null:SoLoud.instance.getRelativePlaySpeed(source!);
	}

	@override
  void setPlaybackRate(double value){
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if (isPlaying) {
      playbackRate = value;
			source == null?null:SoLoud.instance.setRelativePlaySpeed(source!,value);
		}
	}

	@override
  bool getLoop() {
		if (!hasPlaybackControl ) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return false;
		}

		return source == null?false:SoLoud.instance.getLooping(source!);
	}

	@override
  void setLoop(bool value ){
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		loop = value;

		if(source != null) SoLoud.instance.setLooping(source!, value);
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
		return source != null?SoLoud.instance.getPan(source!):0;
	}

	@override
  void setBalance(double value ){
    _balance = value;
		if(source != null)SoLoud.instance.setPan(source!,value);
	}

	@override
  double? getVolume() {
		return source == null? 0:SoLoud.instance.getVolume(source!);
	}

  @override
	void setVolume(double value ){
    _volume = value;
    if(source != null) SoLoud.instance.setVolume(source!,value);
	}
}