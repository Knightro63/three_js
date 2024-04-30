import 'audio.dart';

class AudioAnalyser {

	AudioAnalyser(Audio audio, [int fftSize = 2048 ]) {
		this.analyser = audio.context.createAnalyser();
		this.analyser.fftSize = fftSize;
		this.data = new Uint8Array(this.analyser.frequencyBinCount);
		audio.getOutput().connect(this.analyser);
	}


	getFrequencyData() {
		this.analyser.getByteFrequencyData(this.data);
		return this.data;
	}

	double getAverageFrequency() {
		double value = 0;
		final data = getFrequencyData();

		for (int i = 0; i < data.length; i ++ ) {
			value += data[i];
		}

		return value / data.length;
	}
}
