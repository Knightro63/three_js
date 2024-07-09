import 'dart:typed_data';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_animations/three_js_animations.dart';
import '../skeleton_helper.dart';

class SkeletonUtilsOptions{
  SkeletonUtilsOptions({
    this.preserveMatrix = true,
    this.preservePosition = true,
    this.preserveHipPosition = false,
    this.useTargetMatrix = false,
    this.useFirstFramePosition = false,
    this.fps = 30,
    this.hip = 'hip',
    this.offsets,
    Map<String,dynamic>? names
  }){
    this.names = names ?? {};
  }
  
  bool preserveMatrix;
  bool preservePosition;
  bool preserveHipPosition;
  bool useTargetMatrix;
  bool useFirstFramePosition;
  int fps;
  String hip;
  dynamic offsets;
  Map<String,dynamic> names = {};
}

class SkeletonUtils {
  static retarget(target, source, [SkeletonUtilsOptions? options]) {
    final pos = Vector3(),
        quat = Quaternion(),
        scale = Vector3(),
        bindBoneMatrix = Matrix4(),
        relativeMatrix = Matrix4(),
        globalMatrix = Matrix4();

    options = options ?? SkeletonUtilsOptions();

    options.preserveMatrix = options.preserveMatrix;
    options.preservePosition = options.preservePosition;
    options.preserveHipPosition = options.preserveHipPosition;
    options.useTargetMatrix = options.useTargetMatrix;
    options.hip = options.hip;
    options.names = options.names;

    List<Bone> sourceBones = source is Object3D ? (source.skeleton?.bones ?? []) : getBones(source);
    List<Bone> bones = target is Object3D ? (target.skeleton?.bones ?? []) : getBones(target);

    List? bindBones;
    Bone bone;
    String name;
    Bone? boneTo;
    List<Vector3> bonesPosition = [];

    // reset bones

    if (target.isObject3D) {
      target.skeleton.pose();
    } else {
      options.useTargetMatrix = true;
      options.preserveMatrix = false;
    }

    if (options.preservePosition) {
      bonesPosition = [];

      for (int i = 0; i < bones.length; i++) {
        bonesPosition.add(bones[i].position.clone());
      }
    }

    if (options.preserveMatrix) {
      target.updateMatrixWorld();
      target.matrixWorld.identity();
      for (int i = 0; i < target.children.length; ++i) {
        target.children[i].updateMatrixWorld(true);
      }
    }

    if (options.offsets != null) {
      bindBones = [];

      for (int i = 0; i < bones.length; ++i) {
        bone = bones[i];
        name = options.names[bone.name] ?? bone.name;

        if (options.offsets && options.offsets[name]) {
          bone.matrix.multiply(options.offsets[name]);
          bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
          bone.updateMatrixWorld();
        }

        bindBones.add(bone.matrixWorld.clone());
      }
    }

    for (int i = 0; i < bones.length; ++i) {
      bone = bones[i];
      name = options.names[bone.name] ?? bone.name;

      boneTo = getBoneByName(name, sourceBones);

      globalMatrix.setFrom(bone.matrixWorld);

      if (boneTo != null) {
        boneTo.updateMatrixWorld();

        if (options.useTargetMatrix) {
          relativeMatrix.setFrom(boneTo.matrixWorld);
        } else {
          relativeMatrix.setFrom(target.matrixWorld).invert();
          relativeMatrix.multiply(boneTo.matrixWorld);
        }

        // ignore scale to extract rotation

        scale.setFromMatrixScale(relativeMatrix);
        relativeMatrix.scaleByVector(scale.setValues(1 / scale.x, 1 / scale.y, 1 / scale.z));

        // apply to global matrix

        globalMatrix.makeRotationFromQuaternion(quat.setFromRotationMatrix(relativeMatrix));

        if (target is Object3D) {
          final boneIndex = bones.indexOf(bone),
              wBindMatrix = bindBones != null
                  ? bindBones[boneIndex]
                  : bindBoneMatrix.setFrom(target.skeleton!.boneInverses[boneIndex]).invert();

          globalMatrix.multiply(wBindMatrix);
        }

        globalMatrix.copyPosition(relativeMatrix);
      }

      if (bone.parent != null && bone.parent is Bone) {
        bone.matrix.setFrom(bone.parent!.matrixWorld).invert();
        bone.matrix.multiply(globalMatrix);
      } else {
        bone.matrix.setFrom(globalMatrix);
      }

      if (options.preserveHipPosition && name == options.hip) {
        bone.matrix.setPositionFromVector3(pos.setValues(0, bone.position.y, 0));
      }

      bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);

      bone.updateMatrixWorld();
    }

    if (options.preservePosition) {
      for (int i = 0; i < bones.length; ++i) {
        bone = bones[i];
        name = options.names[bone.name] ?? bone.name;

        if (name != options.hip) {
          bone.position.setFrom(bonesPosition[i]);
        }
      }
    }

    if (options.preserveMatrix) {
      // restore matrix

      target.updateMatrixWorld(true);
    }
  }

  static retargetClip(target, source, AnimationClip clip, [SkeletonUtilsOptions? options]) {
    options = options ?? SkeletonUtilsOptions();

    options.useFirstFramePosition = options.useFirstFramePosition;
    options.fps = options.fps;
    options.names = options.names;

    if (source is! Object3D) {
      source = getHelperFromSkeleton(source);
    }

    final numFrames = (clip.duration * (options.fps / 1000) * 1000).round(),
        delta = 1 / options.fps,
        convertedTracks = <KeyframeTrack>[],
        mixer = AnimationMixer(source),
        bones = getBones(target.skeleton),
        boneDatas = [];
        
    Vector3? positionOffset;
    Bone? bone, boneTo; 
    Map? boneData;
    String name;

    mixer.clipAction(clip)?.play();
    mixer.update(0);

    source.updateMatrixWorld();

    for (int i = 0; i < numFrames; ++i) {
      double time = i * delta;

      retarget(target, source, options);

      for (int j = 0; j < bones.length; ++j) {
        name = options.names[bones[j].name] ?? bones[j].name;

        boneTo = getBoneFromSkeleton(name, source.skeleton!);

        if (boneTo != null) {
          bone = bones[j];
          boneData = boneDatas[j] = boneDatas[j] ?? {"bone": bone};

          if (options.hip == name) {
            if (boneData!['pos'] == null) {
              boneData['pos'] = {"times": Float32List(numFrames), "values": Float32List(numFrames * 3)};
            }

            if (options.useFirstFramePosition) {
              if (i == 0) {
                positionOffset = bone.position.clone();
              }

              bone.position.sub(positionOffset!);
            }

            boneData['pos']['times'][i] = time;

            bone.position.copyIntoArray(boneData['pos']['values'], i * 3);
          }

          if (boneData!['quat'] == null) {
            boneData['quat'] = {"times": Float32List(numFrames), "values": Float32List(numFrames * 4)};
          }

          boneData['quat']['times'][i] = time;

          bone.quaternion.toArray(boneData['quat']['values'], i * 4);
        }
      }

      mixer.update(delta);

      source.updateMatrixWorld();
    }

    for (int i = 0; i < boneDatas.length; ++i) {
      boneData = boneDatas[i];

      if (boneData != null) {
        if (boneData['pos']) {
          convertedTracks.add(VectorKeyframeTrack('.bones[${boneData['bone']['name']}].position', boneData['pos']['times'], boneData['pos']['values'], null));
        }

        convertedTracks.add(QuaternionKeyframeTrack('.bones[${boneData['bone']['name']}].quaternion', boneData['quat']['times'], boneData['quat']['values'], null));
      }
    }

    mixer.uncacheAction(clip);

    return AnimationClip(clip.name, -1, convertedTracks);
  }

  static SkeletonHelper getHelperFromSkeleton(Skeleton skeleton) {
    final source = SkeletonHelper(skeleton.bones[0]);
    source.skeleton = skeleton;
    return source;
  }

  static Map<String,dynamic> getSkeletonOffsets(target, source, [SkeletonUtilsOptions? options]) {
    options = options ?? SkeletonUtilsOptions();

    final targetParentPos = Vector3(),
        targetPos = Vector3(),
        sourceParentPos = Vector3(),
        sourcePos = Vector3(),
        targetDir = Vector2(),
        sourceDir = Vector2();

    options.hip = options.hip;
    options.names = options.names;

    if (source is! Object3D) {
      source = getHelperFromSkeleton(source);
    }

    final List<String> nameKeys = options.names.keys.toList();
    final List<String> nameValues = options.names.values.toList() as List<String>;
    final List<Bone> sourceBones = source.skeleton?.bones ?? [],//source is Object3D ? (source.skeleton?.bones ?? []) : getBones(source),
      bones = target is Object3D ? (target.skeleton?.bones ?? []) : getBones(target);
    Map<String,dynamic> offsets = {};

    Bone bone;
    Bone? boneTo;
    String name;
    int i;

    target.skeleton.pose();

    for (i = 0; i < bones.length; ++i) {
      bone = bones[i];
      name = options.names[bone.name] ?? bone.name;

      boneTo = getBoneByName(name, sourceBones);

      if (boneTo != null && name != options.hip) {
        final boneParent = getNearestBone(bone.parent!, nameKeys.toList()),
            boneToParent = getNearestBone(boneTo.parent!, nameValues.toList());

        boneParent?.updateMatrixWorld();
        boneToParent?.updateMatrixWorld();

        targetParentPos.setFromMatrixPosition(boneParent!.matrixWorld);
        targetPos.setFromMatrixPosition(bone.matrixWorld);

        sourceParentPos.setFromMatrixPosition(boneToParent!.matrixWorld);
        sourcePos.setFromMatrixPosition(boneTo.matrixWorld);

        targetDir
            .sub2(Vector2(targetPos.x, targetPos.y), Vector2(targetParentPos.x, targetParentPos.y))
            .normalize();

        sourceDir
            .sub2(Vector2(sourcePos.x, sourcePos.y), Vector2(sourceParentPos.x, sourceParentPos.y))
            .normalize();

        final laterialAngle = targetDir.angle() - sourceDir.angle();
        final offset = Matrix4().makeRotationFromEuler(Euler(0, 0, laterialAngle));

        bone.matrix.multiply(offset);
        bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
        bone.updateMatrixWorld();
        offsets[name] = offset;
      }
    }

    return offsets;
  }

  static void renameBones(skeleton, names) {
    final bones = getBones(skeleton);

    for (int i = 0; i < bones.length; ++i) {
      final bone = bones[i];

      if (names[bone.name]) {
        bone.name = names[bone.name];
      }
    }

    console.info("SkeletonUtils.renameBones need confirm how return this  ");
  }

  static List<Bone> getBones( skeleton) {
    return skeleton is List ? skeleton : skeleton.bones;
  }

  static Bone? getBoneFromSkeleton(String name, Skeleton skeleton) {
    final bones = getBones(skeleton);
    for (int i = 0; i < bones.length; i++) {
      if (name == bones[i].name) return bones[i];
    }

    return null;
  }

  static Bone? getBoneByName(String name, List<Bone> bones) {
    for (int i = 0; i < bones.length; i++) {
      if (name == bones[i].name) return bones[i];
    }

    return null;
  }

  static Bone? getNearestBone(Object3D bone, List<String> names) {
    while (bone is Bone) {
      if (names.contains(bone.name)) {
        return bone;
      }

      bone = bone.parent!;
    }

    return null;
  }

  static Map<String,dynamic> findBoneTrackData(String name, List<KeyframeTrack> tracks) {
    final regexp = RegExp(r"\[(.*)\]\.(.*)");

    final Map<String,dynamic> result = {"name": name};

    for (int i = 0; i < tracks.length; ++i) {
      // 1 is track name
      // 2 is track type
      final trackData = regexp.firstMatch(tracks[i].name);
      if (trackData != null && name == trackData.group(1)) {
        result[trackData.group(2)!] = i;
      }
    }

    return result;
  }

  static List<Bone> getEqualsBonesNames(Skeleton skeleton, Skeleton targetSkeleton) {
    final sourceBones = getBones(skeleton);
    final targetBones = getBones(targetSkeleton);
    final List<Bone> bones = [];

    search:
    for (int i = 0; i < sourceBones.length; i++) {
      final boneName = sourceBones[i].name;

      for (int j = 0; j < targetBones.length; j++) {
        if (boneName == targetBones[j].name) {
          bones.add(targetBones[j]);
          continue search;
        }
      }
    }

    return bones;
  }

  static clone(Object3D source) {
    final sourceLookup = {};
    final cloneLookup = {};

    final clone = source.clone();

    parallelTraverse(source, clone, (sourceNode, clonedNode) {
      sourceLookup[clonedNode] = sourceNode;
      cloneLookup[sourceNode] = clonedNode;
    });

    clone.traverse((node) {
      if (!node.runtimeType.toString().contains("SkinnedMesh")) return;

      final clonedMesh = node;
      final Object3D sourceMesh = sourceLookup[node];
      final sourceBones = sourceMesh.skeleton?.bones;

      clonedMesh.skeleton = sourceMesh.skeleton?.clone();
      clonedMesh.bindMatrix?.setFrom(sourceMesh.bindMatrix!);

      clonedMesh.skeleton?.bones = List<Bone>.from(sourceBones!.map((bone) {
        return cloneLookup[bone];
      }).toList());
      
      if(clonedMesh is SkinnedMesh){
        clonedMesh.bind(clonedMesh.skeleton!, clonedMesh.bindMatrix);
      }
    });

    return clone;
  }

  static void parallelTraverse(Object3D? a, Object3D? b, void Function(Object3D?,Object3D?) callback) {
    callback(a, b);
    if(a != null){
      for (int i = 0; i < a.children.length; i++) {
        Object3D? bc;
        if (b != null && i < b.children.length) {
          bc = b.children[i];
        }
        parallelTraverse(a.children[i], bc, callback);
      }
    }
  }
}
