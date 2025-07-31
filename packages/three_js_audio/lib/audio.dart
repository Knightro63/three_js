import 'dart:async';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:three_js_core/three_js_core.dart';

/// This utility class holds static references to some global audio objects.
///
/// You can use as a helper to very simply play a sound or a background music.
/// Alternatively you can create your own instances and control them yourself.
class Audio extends Object3D{
  bool autoplay;
  bool loop;
  bool hasPlaybackControl;

  Player? _player;
  
  //Uint8List? _buffer;

  int loopEnd = 0;
  int loopStart = 0;
  //double? duration;
  double playbackRate;

  late double _volume;
  late double _balance;
  //AudioLoader _loader = AudioLoader();

  Timer? _delay;
  bool get isPlaying => _player?.state.playing ?? false;
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
    MediaKit.ensureInitialized();
    _balance = balance;
    _volume = volume;

    _player ??= Player();
    setVolume(_volume);
    setBalance(_balance);
    setPlaybackRate(playbackRate);
    _player!.open(Media(_convert(path),start: Duration(milliseconds: loopStart)),play: autoplay).then((_){
      if(loop){
        _player!.setPlaylistMode(PlaylistMode.single);
      }
    });
  }

  // void setBuffer(Uint8List buffer){
  //   _buffer = buffer;
  // }

  @override
  void dispose(){
    _delay?.cancel();
    _player?.dispose();
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
    if(delay == 0){
      replay();
    }
    else{
      Future.delayed(Duration(milliseconds: delay),replay);
    }
  }

  Future<void> replay() async{
    await _player?.seek(Duration.zero);
    await _player?.play();
  }

  static String _convert(dynamic url){
    if(url is File){
      return 'file:///${url.path}';
    }
    else if(url is Uri){
      return url.path;
    }
    else if(url is String){
      if(url.contains('http://') || url.contains('https://')){  
        return url;
      }
      else if(url.contains('assets')){
        return 'asset:///$url';
      }
    }

    throw('File type not allowed. Must be a path, asset, or url string.');
  }

  /// Stops the currently playing background music track (if any).
  Future<void> stop() async {
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

    _delay?.cancel();
    _delay = null;
    _player?.stop();
  }

  /// Resumes the currently played (but resumed) background music.
  Future<void> resume() async {
    await _player?.play();
  }

  /// Pauses the background music without unloading or resetting the audio
  /// player.
  Future<void> pause() async {
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if(isPlaying) {
      _player?.pause();
    }

    _delay?.cancel();
    _delay = null;
  }

	double? getPlaybackRate() {
		return _player?.state.rate;
	}

	void setPlaybackRate(double value){
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		if (isPlaying) {
      playbackRate = value;
      _player?.setRate(value);
		}
	}

	bool getLoop() {
		if (!hasPlaybackControl ) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return false;
		}

		return _player?.state.playlist == PlaylistMode.single;
	}

	void setLoop(bool value ){
		if (!hasPlaybackControl) {
			console.warning( 'Audio: this Audio has no playback control.' );
			return;
		}

		loop = value;

		if (isPlaying && value) {
			_player?.setPlaylistMode(PlaylistMode.single);
		}
    else if(isPlaying){
      _player?.setPlaylistMode(PlaylistMode.none);
    }
	}

	void setLoopStart(int value ) {
		loopStart = value;
	}

	void setLoopEnd(int value ) {
		loopEnd = value;
	}

	double? getBalance() {
		return 0;//_player != null?_player?.state.audioParams. getPan(source!):0;
	}

	void setBalance(double value ){
    _balance = value;
    //_player?.se
	}

	double? getVolume() {
		return _player?.state.volume;
	}

	void setVolume(double value ){
    _volume = value;
    _player?.setVolume(value*100);
	}
}
