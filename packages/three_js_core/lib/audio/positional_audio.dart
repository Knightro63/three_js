import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

final _position = Vector3.zero();
final _quaternion = Quaternion.identity();
final _scale = Vector3.zero();
final _orientation = Vector3.zero();

class _AudioArea{
  _AudioArea(this.inside, [this.angle = 0, this.side = 0]);

  bool inside;
  double angle;
  double side;
}

extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

class PositionalAudio extends Object3D{
  Audio audioSource;
  double refDistance;
  double maxDistance;
  int rolloffFactor;

  double coneInnerAngle;
  double coneOuterAngle;
  double coneOuterGain;

  Object3D listner;

	PositionalAudio({
    required this.audioSource,
    required this.listner,
    this.refDistance = 0,
    this.maxDistance = double.maxFinite,
    this.coneInnerAngle = 90,
    this.coneOuterGain = 1,
    this.coneOuterAngle = 180,
    this.rolloffFactor = 3,
  });

	void setDirectionalCone(double coneInnerAngle, double coneOuterAngle, double coneOuterGain) {
		this.coneInnerAngle = coneInnerAngle;
		this.coneOuterAngle = coneOuterAngle;
		this.coneOuterGain = coneOuterGain;
	}

  _AudioArea _insideAudioArea(Vector3 audioPos, Vector3 audioDirection, Vector3 objectPos, double angle){
    if(angle <= 180){
      final normalizedDir = audioDirection.normalize();
      final objVector = objectPos.sub(audioPos);
      final disOnViewAxis = objVector.dot(normalizedDir);
      if (disOnViewAxis < 0.0) return _AudioArea(false);
      final temp = objVector.cross(normalizedDir).length;
      final theta = math.atan(temp/disOnViewAxis);
      final sign = Plane().setFromCoplanarPoints(Vector3(), objectPos, audioPos).normal.z.sign;
      if(angle == 180 || maxDistance == double.maxFinite) return _AudioArea(true,theta.toDeg(),sign);
      final r = math.tan((angle/2).toRad())*disOnViewAxis;
      return _AudioArea(temp <= r,theta.toDeg(),sign);
    }
    else{
      final normalizedDir = audioDirection.scale(-1).normalize();
      final objVector = objectPos.sub(audioPos);
      final disOnViewAxis = objVector.dot(normalizedDir);
      if (disOnViewAxis < 0.0) return _AudioArea(true);
      final temp = objVector.cross(normalizedDir).length;
      final r = math.tan((angle/2).toRad())*disOnViewAxis;
      final theta = math.atan(temp/disOnViewAxis);
      final sign = Plane().setFromCoplanarPoints(Vector3(), objectPos, audioPos).normal.z.sign;
      return _AudioArea(temp > r,theta.toDeg(),sign);
    }
  }
  
  bool get hasPlaybackControl => audioSource.hasPlaybackControl;
  bool get isPlaying => audioSource.isPlaying;
  Matrix4 get matrixWorld => audioSource.matrixWorld;
  bool get autoplay => audioSource.autoplay;
  bool get loop => audioSource.loop;
  int get loopEnd => audioSource.loopEnd;
  int get loopStart => audioSource.loopStart;
  double get playbackRate => audioSource.playbackRate;
  String get path => audioSource.path;

  set hasPlaybackControl(bool value){
    audioSource.hasPlaybackControl = value;
  }
  set autoplay(bool value){
    audioSource.autoplay = value;
  }
  set loop(bool value){
    audioSource.loop = value;
  }
  set loopEnd(int value){
    audioSource.loopEnd = value;
  }
  set loopStart(int value){
    audioSource.loopStart = value;
  }
  set playbackRate(double value){
    audioSource.playbackRate = value;
  }
  set path(String value){
    audioSource.path = value;
  }

  Future<void> play([int delay = 0]) async{
    await audioSource.play(delay);
  }

  Future<void> replay() async{
    await audioSource.replay();
  }

  Future<void> stop() async {
    await audioSource.stop();
  }

  Future<void> resume() async {
    await audioSource.resume();
  }

  Future<void> pause() async {
    await audioSource.pause();
  }

	double? getPlaybackRate() {
    return audioSource.getPlaybackRate();
  }

	void setPlaybackRate(double value){
    audioSource.setPlaybackRate(value);
  }

	bool getLoop() {
    return audioSource.getLoop();
  }

	void setLoop(bool value ){
    audioSource.setLoop(value);
  }

	void setLoopStart(int value ) {
		audioSource.setLoopStart(value);
	}

	void setLoopEnd(int value ) {
		audioSource.setLoopEnd(value);
	}

	double? getBalance() {
		return audioSource.getBalance();
	}

	void setBalance(double value ){
    audioSource.setBalance(value);
	}

	double? getVolume() {
		return audioSource.getVolume();
	}

  void setVolume(double volume){
    print(volume);
    audioSource.setVolume(volume);
  }

  @override
  void dispose(){
    super.dispose();
    audioSource.dispose();
  }

  @override
  void updateMatrixWorld([bool force = false]) {
		super.updateMatrixWorld( force );

		if (hasPlaybackControl && !isPlaying) return;

		matrixWorld.decompose( _position, _quaternion, _scale );
		_orientation.setValues( 0, 0, 1 ).applyQuaternion( _quaternion );

    final dist = _position.distanceTo(listner.position);

    // Sphere of influence
    if(dist <= maxDistance){
      if(_insideAudioArea(_position.clone(),_orientation,listner.position.clone(),coneOuterAngle).inside){ //is inside cone
        //check balance
        _AudioArea aa = _insideAudioArea(_position.clone(),_orientation,listner.position.clone(),coneInnerAngle);
        
        final diffAngle = (coneOuterAngle-coneInnerAngle)/2;
        final double anglePercent = aa.inside?1:(coneOuterAngle/2-aa.angle)/diffAngle;

        //check volume
        if(dist >= refDistance && dist <= maxDistance){
          //dist to percent
          final double percent = ((maxDistance-dist)/(maxDistance-refDistance)).toPrecision(rolloffFactor)*anglePercent;
          
          if(getVolume() != percent){
            setVolume(percent);
          }
        }
        else if(dist <= refDistance && getVolume() != 1.0){
          setVolume(1.0);
        }
        else if(dist > refDistance && getVolume() != 0.0){
          setVolume(0);
        }

        if(!aa.inside){ ///is not inside little cone
          // dist from little cone
          if(getBalance() != anglePercent){
            setBalance((1-anglePercent)*-aa.side);
          }
        }
        else if(getBalance() != 0.0){
          setBalance(0.0);
        }
      }
      else{ // is inside little sphere
        if(dist <= refDistance){
          //dist to percent
          final double percent = ((refDistance-dist)/refDistance).toPrecision(rolloffFactor);
          if(getVolume() != percent){
            setVolume(percent);
          }
        }
        else if(dist == 0 && getVolume() != 1.0){
          setVolume(1.0);
        }
        else if(dist > refDistance && getVolume() != 0.0){
          setVolume(0);
        }
      }
    }
    else if(getVolume() != 0.0){
      setVolume(0);
    }
	}
}
