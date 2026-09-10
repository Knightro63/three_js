import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core/objects/skinned_mesh.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart' as three;

class InstancedAnimation extends three.Group{
  final List<AnimationClip> animations = [];
  final List<InstancedSkinnedMeshData> instancesData = [];
  final List<InstancedSkinnedMeshHandler> instancedSkinnedMeshes = [];
  List<Map<String, AnimationAction>> get animationsActions => 
      instancedSkinnedMeshes.map((mesh) => mesh.animationsActionsByName).toList();
  List<AnimationMixer> get mixers => 
      instancedSkinnedMeshes
          .map((mesh) => mesh.mixer)
          .whereType<AnimationMixer>()
          .toList();

  int maxLevelOfDetail = 0;
  final Map<String, AnimationClip> animationsByName = {};

  InstancedAnimation({required three.Object3D object, List? startAnimations, required int count}) {
    startAnimations ??= [];
    int maxLevel = 0;

    // Add information about the level in the tree that the bone is
    object.traverse((o) {
      if (o is three.Bone) {
        if (o.parent != null && o.parent is three.Bone) {
          if (o.parent!.userData['level'] == null) {
            o.parent!.userData['level'] = 0;
          }
          
          o.userData['level'] = (o.parent!.userData['level'] as int) + 1;

          if ((o.userData['level'] as int) > maxLevel) {
            maxLevel = o.userData['level'] as int;
          }
        }
      }
    });

    object.traverse((o) {
      if (o is three.Bone) {
        o.userData['maxLevel'] = maxLevel;
      }
    });

    maxLevelOfDetail = maxLevel;

    for (final clip in startAnimations) {
      final animationClip = clip.clone();
      print(animationClip.name);
      animationsByName[animationClip.name] = animationClip;
      animations.add(animationClip);
    }

    final skinnedMeshes = _getSkinnedMesh(object);
    for (final skinnedMesh in skinnedMeshes) {
      final instancedSkinnedMeshHandler = InstancedSkinnedMeshHandler(
        count: count,
        skinnedMesh: skinnedMesh,
        animations: animations,
        instancesData: instancesData,
        object: object,
      );

      instancedSkinnedMeshes.add(instancedSkinnedMeshHandler);
      children.add(instancedSkinnedMeshHandler.instancedMesh);
    }

  }

  void instanceMatrixNeedsUpdate() {
    for (int i = 0; i < instancedSkinnedMeshes.length; i++) {
      instancedSkinnedMeshes[i].instancedMesh.instanceMatrix!.needsUpdate = true;
    }
  }

  void dispose() {
    for (int i = 0; i < instancedSkinnedMeshes.length; i++) {
      instancedSkinnedMeshes[i].dispose();
    }
  }
  
  void setMatrixAt(int index, Matrix4 matrix) {
    // 1. Safety boundary check
    if (index >= instancesData.length) return;

    final instanceData = instancesData[index];

    // 2. Decompose the matrix into position, rotation, and scale components 
    // so that updateInstance() can accurately read them.
    matrix.decompose(
      instanceData.position, 
      instanceData.rotation, 
      instanceData.scale
    );

    // 3. Loop through your handlers and force them to re-evaluate the animations,
    // update the matrices, and flag instanceMatrix!.needsUpdate = true.
    for (int i = 0; i < instancedSkinnedMeshes.length; i++) {
      instancedSkinnedMeshes[i].updateSkinnedMeshMatrix(index);
      
      // Explicitly notify the GPU that the float attribute array buffer has changed
      final pool = instancedSkinnedMeshes[i].instancedMesh;
      if (pool.instanceMatrix != null) {
        pool.instanceMatrix!.needsUpdate = true;
      }
    }
  }
  double deltaTime = 0;

  void update(double deltaTime) {
    this.deltaTime = deltaTime;
    for (int i = 0; i < instancesData.length; i++) {
      updateInstance(i, deltaTime);
    }
  }

  void updateInstance(int i, double deltaTime) {
    final instanceData = instancesData[i];
    
    instanceData.animations.forEach((animationName, animation) {
      animation.time = (animation.time + deltaTime) % (animationsByName[animationName]?.duration.toDouble() ?? 0);
    });
    for (int j = 0; j < instancedSkinnedMeshes.length; j++) {
      instancedSkinnedMeshes[j].updateInstance(i, deltaTime);
    }
  }

  void updateInstanceMap(Map<String, AnimationState> animationsMap, int i, double deltaTime) {
    final instanceData = instancesData[i];
    
    instanceData.animations.forEach((animationName, animation) {
      animation.time = (animation.time + deltaTime) % (animationsByName[animationName]?.duration.toDouble() ?? 0);
    });
    for (int j = 0; j < instancedSkinnedMeshes.length; j++) {
      instancedSkinnedMeshes[j].updateInstanceMap(animationsMap, i, deltaTime);
    }
  }

  void updateMixer(Map<String, AnimationState> animations, double dt) {
    for (int i = 0; i < instancedSkinnedMeshes.length; i++) {
      instancedSkinnedMeshes[i].updateMixer(animations,dt);
    }
  }

  void stopAnimation(int i) {
    for (int j = 0; j < instancedSkinnedMeshes.length; j++) {
      instancedSkinnedMeshes[j].stopAnimation(i);
    }
  }

  void updateSkinnedMeshMatrix(int i) {
    for (int j = 0; j < instancedSkinnedMeshes.length; j++) {
      instancedSkinnedMeshes[j].updateSkinnedMeshMatrix(i);
    }
  }

  void addInstance(InstancedSkinnedMeshData data) {
    final instanceIndex = instancesData.length;
    instancesData.add(data);
    
    for (int i = 0; i < instancedSkinnedMeshes.length; i++) {
      instancedSkinnedMeshes[i].updateInstance(instanceIndex, 0);
    }
  }

  InstancedAnimation clear(){
    for (int i = 0; i < instancesData.length; i++) {
      setMatrixAt(i,Matrix4());
    }

    instancesData.clear();

    return this;
  }

  List<three.SkinnedMesh> _getSkinnedMesh( three.Object3D object) {
    final List<three.SkinnedMesh> skinnedMeshes = [];

    if(object is SkinnedMesh){
      skinnedMeshes.add(object);
    }

    // Traverse the scene structure looking for skinned meshes
    object.traverse((o) {
      if (o is three.SkinnedMesh) {
        skinnedMeshes.add(o);
      }
    });

    if (skinnedMeshes.isEmpty) {
      throw Exception("Skinned mesh not found");
    }

    for (int i = 0; i < skinnedMeshes.length; i++) {
      if (skinnedMeshes[i].material is three.GroupMaterial) {
        //throw Exception("Skinned mesh has multiple materials");
        skinnedMeshes[i].material = three.MeshBasicMaterial.fromMap({'color': 0xffffff});//(skinnedMeshes[i].material as GroupMaterial).children.first;
      }
    }

    return skinnedMeshes;
  }
}
