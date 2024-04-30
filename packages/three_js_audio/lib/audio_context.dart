import 'package:audioplayers/audioplayers.dart';

dynamic _context;

extension AC on AudioContext{
	static getContext() {
		_context ??= AudioContext();//( window.AudioContext || window.webkitAudioContext )();
		return _context;
	}

	static setContext(AudioContext value) {
		_context = value;
	}
}
