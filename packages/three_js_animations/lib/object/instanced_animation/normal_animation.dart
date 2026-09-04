import 'dart:math' as math;
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class AnimationInstance {
  final Object3D model;
  final void Function(double deltaTime) update;

  AnimationInstance({required this.model, required this.update});

  static AnimationInstance createInstance(Object3D gltf, List? animations, Vector3 position) {
    // 1. Cleanly clone the scene tree graph hierarchy structure
    final Object3D model = gltf.clone();
    model.position.setFrom(position);

    // 2. Instantiate a fresh mixer tied to this specific clone instance mesh context
    final mixer = AnimationMixer(model);

    // 3. Roll a random clip index from the gltf tracks array to play on spawn
    final List? gltfAnims = animations;
    if (gltfAnims != null && gltfAnims.isNotEmpty) {
      final int randomIndex = math.Random().nextInt(gltfAnims.length);
      final clip = gltfAnims[randomIndex];
      
      if (clip is AnimationClip) {
        mixer.clipAction(clip.clone())?.play();
      }
    }

    // 4. Return the wrapped tracker callback closure structure
    return AnimationInstance(
      model: model,
      update: (double deltaTime) {
        mixer.update(deltaTime);
      },
    );
  }
}
