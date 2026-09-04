import 'package:three_js_math/three_js_math.dart';

class AnimationState {
  double weight;
  double time;
  String name;

  double timeScale = 1.0;
  double repetitions = double.infinity;
  int loopType = LoopRepeat;

  bool clampWhenFinished = false;
  bool enabled = false;

  AnimationState({required this.weight, required this.time, required this.name});

  void setEffectiveWeight(double weight){
    this.weight = weight;
  }

  void setLoop(int type, double iterations){
    repetitions = iterations;
    loopType = type;
  }

  void setEffectiveTimeScale(double timeScale){
    this.timeScale = timeScale;
  }

  void play(){
    enabled = true;
  }

  // Construct default active states directly from baked clips
  static Map<String, AnimationState> fromClips(List clips) {
    Map<String, AnimationState> states = {};
    for (int i = 0; i < clips.length; i++) {
      final clip = clips[i];
      states[clip.name] = AnimationState(
        name: clip.name,
        weight: i == 0 ? 1.0 : 0.0,  // First clip defaults to active weight 1.0
        time: 0.0,
      );
    }
    return states;
  }
}