import 'dart:async';
import 'package:three_js_core/three_js_core.dart';

/// This utility class holds static references to some global audio objects.
///
/// You can use as a helper to very simply play a sound or a background music.
/// Alternatively you can create your own instances and control them yourself.
///
/// Please Use "VideoAudio, FlutterAudio, or AudioLatency"
abstract class Audio extends Object3D {
  bool autoplay;
  bool loop;
  bool hasPlaybackControl;
  int loopEnd = 0;
  int loopStart = 0;
  //double? duration;
  double playbackRate;
  bool get isPlaying => false;
  String path;

  Audio(
      {required this.path,
      this.playbackRate = 1.0,
      this.hasPlaybackControl = true,
      this.autoplay = false,
      this.loop = false});

  /// Plays a single run of the given [file], with a given [volume].
  Future<void> play([int delay = 0]) async {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  Future<void> replay() async {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  /// Stops the currently playing background music track (if any).
  Future<void> stop() async {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  /// Resumes the currently played (but resumed) background music.
  Future<void> resume() async {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  /// Pauses the background music without unloading or resetting the audio
  /// player.
  Future<void> pause() async {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  double? getPlaybackRate() {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  void setPlaybackRate(double value) {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  bool getLoop() {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  void setLoop(bool value) {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  void setLoopStart(int value) {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  void setLoopEnd(int value) {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  double? getBalance() {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  void setBalance(double value) {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  double? getVolume() {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  void setVolume(double value) {
    throw ('Currently Not Implimented! Please Use "VideoAudio, FlutterAudio, or AudioLatency".');
  }

  /// [meta] - object containing metadata such as textures or images for the scene.
  ///
  /// Convert the scene to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    Map<String, dynamic> data = super.toJson(meta: meta);

    data['autoplay'] = autoplay;
    data['loop'] = loop;
    data['hasPlaybackControl'] = hasPlaybackControl;
    data['loopEnd'] = loopEnd;
    data['loopStart'] = loopStart;
    data['playbackRate'] = playbackRate;
    data['path'] = path;

    return data;
  }

  @override
  dynamic getProperty(String propertyName, [int? offset]) {
    if (propertyName == 'autoplay') {
      return autoplay;
    } else if (propertyName == 'loop') {
      return loop;
    } else if (propertyName == 'hasPlaybackControl') {
      return hasPlaybackControl;
    } else if (propertyName == 'loopEnd') {
      return loopEnd;
    } else if (propertyName == 'loopStart') {
      return loopStart;
    } else if (propertyName == 'playbackRate') {
      return playbackRate;
    } else if (propertyName == 'path') {
      return path;
    }
    return super.getProperty(propertyName, offset);
  }

  @override
  Audio setProperty(String propertyName, dynamic value, [int? offset]) {
    if (propertyName == 'autoplay') {
      autoplay = value;
    } else if (propertyName == 'loop') {
      loop = value;
    } else if (propertyName == 'loopEnd') {
      loopEnd = value.toInt();
    } else if (propertyName == 'loopStart') {
      loopStart = value.toInt();
    } else if (propertyName == 'playbackRate') {
      playbackRate = value.toDouble();
    } else if (propertyName == 'path') {
      path = value;
    } else {
      super.setProperty(propertyName, value);
    }

    return this;
  }
}
