import 'animation_state.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart';
import '../../animations/animation_clip.dart';
import '../../animations/animation_mixer.dart';
import '../../animations/animation_action.dart';

class InstancedSkinnedMeshData {
  final Vector3 position;
  final Quaternion rotation;
  final Vector3 scale;
  final Map<String, AnimationState> animations;

  InstancedSkinnedMeshData({
    required this.position,
    required this.rotation,
    required this.scale,
    required this.animations,
  });
}

class InstancedSkinnedMeshHandler {
  AnimationMixer? mixer;
  final List<AnimationAction> animationsActions = [];
  final List<InstancedSkinnedMeshData> instancesData;
  final three.SkinnedMesh skinnedMesh;
  final List<AnimationClip> animations;
  late final three.InstancedSkinnedMesh instancedMesh;
  final Map<String, AnimationAction> animationsActionsByName = {};

  InstancedSkinnedMeshHandler({
    required int count,
    required this.skinnedMesh,
    required this.animations,
    required this.instancesData,
    required three.Object3D object,
  }) {
    instancedMesh = three.InstancedSkinnedMesh(
      skinnedMesh.geometry!,
      skinnedMesh.material!,
      count,
    );
    instancedMesh.copy(skinnedMesh);
    instancedMesh.bind(
      skinnedMesh.skeleton!,
      skinnedMesh.bindMatrix!,
    );

    mixer = AnimationMixer(skinnedMesh);

    for (int index = 0; index < animations.length; index++) {
      final clip = animations[index];
      final newClip = clip.clone();
      
      for (final track in newClip.tracks) {
        final String boneName = track.name.split(".")[0];
        final interpolantBone = object.getObjectByName(boneName);
        
        if (interpolantBone != null) {
          track.level = interpolantBone.userData['level'] ?? 0;
        }
      }

      final action = mixer?.clipAction(newClip);
      if (action != null) {
        animationsActionsByName[newClip.name] = action;
        if (animationsActions.length <= index) {
          animationsActions.addAll(List<AnimationAction>.filled((index - animationsActions.length) + 1, action));
        }
        animationsActions[index] = action;
      }
    }

    instancedMesh.frustumCulled = false;
    
    for (final bone in skinnedMesh.skeleton!.bones) {
      bone.matrixWorldAutoUpdate = false;
    }

    instancedMesh.initOverride();
  }

  void updateInstance(int i, double dt) {
    updateMixer(instancesData[i].animations,dt);
    updateSkinnedMeshMatrix(i);
  }

  void updateInstanceMap(Map<String, AnimationState> animationsMap, int i, double dt) {
    updateMixer(animationsMap,dt);
    updateSkinnedMeshMatrix(i);
  }

  void dispose() {
    instancedMesh.dispose();
  }

  void updateMixer(Map<String, AnimationState> animationsMap, double dt) {
    if(mixer == null) return;
    mixer?.stopAllAction();
    
    animationsMap.forEach((animationName, animation) {
      final animationAction = animationsActionsByName[animationName];
      if (animationAction != null) {
        animationAction.play();
        animationAction.setLoop(animation.loopType,animation.repetitions);
        animationAction.setEffectiveWeight(animation.weight);
        animationAction.time = animation.time;
        animationAction..clampWhenFinished = animation.clampWhenFinished;
      }
    });

    mixer?.update(0.001); 
  
    for (final bone in skinnedMesh.skeleton!.bones) {
      if (bone.matrixAutoUpdate) {
        bone.updateMatrix();
      }
      if (bone.matrixWorldNeedsUpdate) {
        if (bone.parent == null) {
          bone.matrixWorld.setFrom(bone.matrix);
        } else {
          bone.matrixWorld.multiply2(
            bone.parent!.matrixWorld,
            bone.matrix,
          );
        }
      }
    }
  }

  void stopAnimation(int animationIndex) {
    if (animationIndex < animationsActions.length) {
      animationsActions[animationIndex].stop();
    }
  }

  void updateSkinnedMeshMatrix(int i) {
    final instanceData = instancesData[i];
    skinnedMesh.scale.setFrom(instanceData.scale);
    skinnedMesh.position.setFrom(instanceData.position);
    skinnedMesh.quaternion.setFrom(instanceData.rotation);
    skinnedMesh.updateMatrix();
    
    instancedMesh.setMatrixAt(i, skinnedMesh.matrix);
    instancedMesh.setBonesAt(i, skinnedMesh.skeleton!);
  }
}
