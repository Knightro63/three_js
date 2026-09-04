import 'dart:math' as math;
import 'normal_animation.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

double _lerp(double a, double b, double t) {
  return a + (b - a) * t;
}

class ViewSensitiveAnimator extends Group{
  final Camera camera;
  final List<AnimationInstance> instances;
  late final BoundingBox modelBoundingBox;
  final List<int> lastUpdateTimes = [];
  
  double maxDistance;
  double minAnimationInterval;
  double maxAnimationInterval;
  
  final List<Bone> rootBones = [];
  final List<SkinnedMesh> skinnedMeshes = [];

  // Reusable spatial math objects to eliminate memory allocations in frame updates
  final Matrix4 _projInverseMatrix = Matrix4.identity();
  final Vector3 _negateCache = Vector3(0, 0, 0);

  ViewSensitiveAnimator({
    required this.camera,
    required this.minAnimationInterval,
    required this.maxAnimationInterval,
    required this.maxDistance,
    required this.instances,
  }) {
    modelBoundingBox = BoundingBox().setFromObject(instances[0].model);
    
    _negateCache.setFrom(instances[0].model.position).negate();
    modelBoundingBox.translate(_negateCache);

    for (int i = 0; i < instances.length; i++) {
      final instance = instances[i];
      
      // Look up properties using object traversal helpers matching your search criteria
      Bone? rootBone;
      instance.model.traverse((object) {
        if (rootBone == null && object is Bone) {
          rootBone = object;
        }
      });
      
      if (rootBone == null) continue;
      rootBone!.matrixWorldAutoUpdate = false;

      SkinnedMesh? skinnedMesh;
      instance.model.traverse((object) {
        if (skinnedMesh == null && object is SkinnedMesh) {
          skinnedMesh = object;
        }
      });

      if (skinnedMesh == null) continue;
      skinnedMesh!.bindMode = "detached";

      rootBones.add(rootBone!);
      skinnedMeshes.add(skinnedMesh!);
      children.add(rootBone!);
    }
  }

  void update(double deltaTime) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final Frustum cameraFrustum = Frustum();
    
    _projInverseMatrix.multiply2(camera.projectionMatrix, camera.matrixWorldInverse);
    cameraFrustum.setFromMatrix(_projInverseMatrix);

    // Initialize list tracking size if needed
    if (lastUpdateTimes.length < instances.length) {
      lastUpdateTimes.addAll(List<int>.filled(instances.length - lastUpdateTimes.length, 0));
    }

    for (int i = 0; i < instances.length; i++) {
      final instance = instances[i];
      final double distance = instance.model.position.distanceTo(camera.position);

      // updateRate, how many times per second we should update the instance,
      // based on the distance from the camera
      final double updateRate = _lerp(
        minAnimationInterval,
        maxAnimationInterval,
        math.min(1.0, math.max(0.0, distance / maxDistance)),
      );

      if (now - lastUpdateTimes[i] < updateRate) {
        continue;
      }

      // Check if instance is inside frustum
      modelBoundingBox.translate(instance.model.position);
      if (!cameraFrustum.intersectsBox(modelBoundingBox)) {
        _negateCache.setFrom(instance.model.position).negate();
        modelBoundingBox.translate(_negateCache);
        continue;
      }
      _negateCache.setFrom(instance.model.position).negate();
      modelBoundingBox.translate(_negateCache);

      double instanceDelta = deltaTime;
      if (lastUpdateTimes[i] != 0) {
        // Delta time derived from system timestamp delta intervals
        instanceDelta = (now - lastUpdateTimes[i]).toDouble();
      } else {
        // Fallback to standard frame time step if uninitialized
        instanceDelta = deltaTime * 1000.0;
      }

      instance.update(instanceDelta / 1000.0);

      // Equivalent execution targeting custom framework flags
      if (skinnedMeshes[i].skeleton != null) {
        // Handle TS annotation override flags securely via your skeleton extensions
        // skeleton.needsUpdate = true context map handling:
        final skeleton = skinnedMeshes[i].skeleton!;
        skeleton.boneTexture?.needsUpdate = true;
      }
      
      rootBones[i].updateWorldMatrix(false, true);
      lastUpdateTimes[i] = now;
    }
  }
}
