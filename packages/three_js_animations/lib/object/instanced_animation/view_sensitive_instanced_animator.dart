import 'dart:math' as math;
import 'animation_state.dart';
import 'instanced_skinned_mesh_handler.dart';
import '../../animations/animation_clip.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart';
import 'instanced_animation.dart';

double _lerp(double a, double b, double t) {
  return a + (b - a) * t;
}

double _roundToNearest(double value, double nearest) {
  if (nearest == 0) return value;
  return (value / nearest).round() * nearest;
}

class AnimationGroup {
  final Map<String, AnimationState> animations;
  final List<int> instancesIDs;

  AnimationGroup({required this.animations, required this.instancesIDs});
}

class ViewSensitiveInstancedAnimator {
  final three.Camera camera;
  late final InstancedAnimation instancedAnimation;
  late final BoundingBox modelBoundingBox;
  final List<int> lastUpdateTimes = [];
  final Map<String, AnimationGroup> animationGroups = {};
  
  double maxDistance;
  double minAnimationInterval;
  double maxAnimationInterval;

  final double _weightPrecision = 0.1;
  
  // Reusable spatial math objects to eliminate memory allocations in frame updates
  final Matrix4 _projInverseMatrix = Matrix4.identity();
  final Vector3 _negateCache = Vector3(0, 0, 0);

  ViewSensitiveInstancedAnimator({
    required this.camera,
    required this.minAnimationInterval,
    required this.maxAnimationInterval,
    required this.maxDistance,
    required three.Object3D object,
    required int count,
  }) {
    instancedAnimation = InstancedAnimation(object: object, count: count);
    modelBoundingBox = BoundingBox().setFromObject(object.clone());
  }

  void addInstance(InstancedSkinnedMeshData data) {
    instancedAnimation.addInstance(data);
  }

  void update(double deltaTime) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final three.Frustum cameraFrustum = three.Frustum();
    
    _projInverseMatrix.multiply2(camera.projectionMatrix, camera.matrixWorldInverse);
    cameraFrustum.setFromMatrix(_projInverseMatrix);

    // Ensure our optimization timestamps lookup array aligns with incoming instances data layout
    if (lastUpdateTimes.length < instancedAnimation.instancesData.length) {
      lastUpdateTimes.addAll(
        List<int>.filled(instancedAnimation.instancesData.length - lastUpdateTimes.length, 0)
      );
    }

    for (int i = 0; i < instancedAnimation.instancesData.length; i++) {
      final instanceData = instancedAnimation.instancesData[i];
      
      instanceData.animations.forEach((animationName, animation) {
        final double animationDuration = instancedAnimation.animationsByName[animationName]!.duration.toDouble();
        animation.time += deltaTime;
        if (animation.time > animationDuration) {
          animation.time = 0.0;
        }
      });

      final double distance = instanceData.position.distanceTo(camera.position);

      // updateRate, how many times per second we should update the instance,
      // based on the distance from the camera
      final double updateRate = _lerp(
        minAnimationInterval, 
        maxAnimationInterval, 
        math.min(1.0, math.max(0.0, distance / maxDistance))
      );

      if (now - lastUpdateTimes[i] < updateRate) {
        continue;
      }

      // Check if instance is inside frustum
      modelBoundingBox.translate(instanceData.position);
      if (!cameraFrustum.intersectsBox(modelBoundingBox)) {
        _negateCache.setFrom(instanceData.position).negate();
        modelBoundingBox.translate(_negateCache);
        continue;
      }
      _negateCache.setFrom(instanceData.position).negate();
      modelBoundingBox.translate(_negateCache);

      final String groupID = _calculateGroupID(instanceData.animations, distance);
      AnimationGroup? group = animationGroups[groupID];

      if (group == null) {
        group = AnimationGroup(
          animations: instanceData.animations,
          instancesIDs: [i],
        );
        animationGroups[groupID] = group;
      } else {
        group.instancesIDs.add(i);
      }

      lastUpdateTimes[i] = now;
    }

    for (final group in animationGroups.values) {
      //instancedAnimation.updateMixer(group.animations);
      for (int k = 0; k < group.instancesIDs.length; k++) {
        instancedAnimation.updateSkinnedMeshMatrix(group.instancesIDs[k]);
      }
    }

    if (animationGroups.isNotEmpty) {
      instancedAnimation.instanceMatrixNeedsUpdate();
    }
    
    animationGroups.clear();
  }

  three.Group get group => instancedAnimation;
  List<AnimationClip> get animations => instancedAnimation.animations;

  String _calculateGroupID(Map<String, AnimationState> animations, double distance) {
    String groupID = "";
    final List<String> animationNames = animations.keys.toList()..sort();
    final double maxAnimationIntervalSeconds = maxAnimationInterval / 1000.0;

    for (final animationName in animationNames) {
      final animation = animations[animationName]!;
      if (distance > maxDistance && animation.weight < 0.99) {
        continue;
      }

      final double time = _roundToNearest(animation.time, maxAnimationIntervalSeconds);
      final double weight = _roundToNearest(animation.weight, _weightPrecision);
      
      groupID += "$animationName-$weight-$time";
    }
    
    return groupID;
  }
}
