import 'dart:typed_data';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_animations/three_js_animations.dart';
import '../skeleton_helper.dart';

class SkeletonUtils {
  static retarget(target, source, [options]) {
    var pos = Vector3(),
        quat = Quaternion(),
        scale = Vector3(),
        bindBoneMatrix = Matrix4(),
        relativeMatrix = Matrix4(),
        globalMatrix = Matrix4();

    options = options ?? {};

    options.preserveMatrix = options.preserveMatrix ?? true;
    options.preservePosition = options.preservePosition ?? true;
    options.preserveHipPosition = options.preserveHipPosition ?? false;
    options.useTargetMatrix = options.useTargetMatrix ?? false;
    options.hip = options.hip ?? 'hip';
    options.names = options.names ?? {};

    List<Bone> sourceBones = source is Object3D ? source.skeleton?.bones : getBones(source);
    List<Bone> bones = target is Object3D ? target.skeleton?.bones : getBones(target);

    var bindBones, bone, name, boneTo, bonesPosition;

    // reset bones

    if (target.isObject3D) {
      target.skeleton.pose();
    } else {
      options.useTargetMatrix = true;
      options.preserveMatrix = false;
    }

    if (options.preservePosition) {
      bonesPosition = [];

      for (var i = 0; i < bones.length; i++) {
        bonesPosition.push(bones[i].position.clone());
      }
    }

    if (options.preserveMatrix) {
      // reset matrix

      target.updateMatrixWorld();

      target.matrixWorld.identity();

      // reset children matrix

      for (var i = 0; i < target.children.length; ++i) {
        target.children[i].updateMatrixWorld(true);
      }
    }

    if (options.offsets) {
      bindBones = [];

      for (var i = 0; i < bones.length; ++i) {
        bone = bones[i];
        name = options.names[bone.name] || bone.name;

        if (options.offsets && options.offsets[name]) {
          bone.matrix.multiply(options.offsets[name]);

          bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);

          bone.updateMatrixWorld();
        }

        bindBones.push(bone.matrixWorld.clone());
      }
    }

    for (var i = 0; i < bones.length; ++i) {
      bone = bones[i];
      name = options.names[bone.name] || bone.name;

      boneTo = getBoneByName(name, sourceBones);

      globalMatrix.setFrom(bone.matrixWorld);

      if (boneTo) {
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

        if (target.isObject3D) {
          var boneIndex = bones.indexOf(bone),
              wBindMatrix = bindBones
                  ? bindBones[boneIndex]
                  : bindBoneMatrix.setFrom(target.skeleton.boneInverses[boneIndex]).invert();

          globalMatrix.multiply(wBindMatrix);
        }

        globalMatrix.copyPosition(relativeMatrix);
      }

      if (bone.parent && bone.parent.isBone) {
        bone.matrix.copy(bone.parent.matrixWorld).invert();
        bone.matrix.multiply(globalMatrix);
      } else {
        bone.matrix.copy(globalMatrix);
      }

      if (options.preserveHipPosition && name == options.hip) {
        bone.matrix.setPosition(pos.setValues(0, bone.position.y, 0));
      }

      bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);

      bone.updateMatrixWorld();
    }

    if (options.preservePosition) {
      for (var i = 0; i < bones.length; ++i) {
        bone = bones[i];
        name = options.names[bone.name] || bone.name;

        if (name != options.hip) {
          bone.position.copy(bonesPosition[i]);
        }
      }
    }

    if (options.preserveMatrix) {
      // restore matrix

      target.updateMatrixWorld(true);
    }
  }

  static retargetClip(target, source, clip, [options]) {
    options = options ?? {};

    options.useFirstFramePosition = options.useFirstFramePosition ?? false;
    options.fps = options.fps ?? 30;
    options.names = options.names ?? [];

    if (!source.isObject3D) {
      source = getHelperFromSkeleton(source);
    }

    var numFrames = (clip.duration * (options.fps / 1000) * 1000).round(),
        delta = 1 / options.fps,
        convertedTracks = <KeyframeTrack>[],
        mixer = AnimationMixer(source),
        bones = getBones(target.skeleton),
        boneDatas = [];
    var positionOffset, bone, boneTo, boneData, name;

    mixer.clipAction(clip)?.play();
    mixer.update(0);

    source.updateMatrixWorld();

    for (var i = 0; i < numFrames; ++i) {
      var time = i * delta;

      retarget(target, source, options);

      for (var j = 0; j < bones.length; ++j) {
        name = options.names[bones[j].name] || bones[j].name;

        boneTo = getBoneByName(name, source.skeleton);

        if (boneTo) {
          bone = bones[j];
          boneData = boneDatas[j] = boneDatas[j] ?? {"bone": bone};

          if (options.hip == name) {
            if (!boneData.pos) {
              boneData.pos = {"times": Float32List(numFrames), "values": Float32List(numFrames * 3)};
            }

            if (options.useFirstFramePosition) {
              if (i == 0) {
                positionOffset = bone.position.clone();
              }

              bone.position.sub(positionOffset);
            }

            boneData.pos.times[i] = time;

            bone.position.toArray(boneData.pos.values, i * 3);
          }

          if (!boneData.quat) {
            boneData.quat = {"times": Float32List(numFrames), "values": Float32List(numFrames * 4)};
          }

          boneData.quat.times[i] = time;

          bone.quaternion.toArray(boneData.quat.values, i * 4);
        }
      }

      mixer.update(delta);

      source.updateMatrixWorld();
    }

    for (var i = 0; i < boneDatas.length; ++i) {
      boneData = boneDatas[i];

      if (boneData) {
        if (boneData.pos) {
          convertedTracks.add(VectorKeyframeTrack(
              '.bones[' + boneData.bone.name + '].position', boneData.pos.times, boneData.pos.values, null));
        }

        convertedTracks.add(QuaternionKeyframeTrack(
            '.bones[' + boneData.bone.name + '].quaternion', boneData.quat.times, boneData.quat.values, null));
      }
    }

    mixer.uncacheAction(clip);

    return AnimationClip(clip.name, -1, convertedTracks);
  }

  static getHelperFromSkeleton(skeleton) {
    var source = SkeletonHelper(skeleton.bones[0]);
    source.skeleton = skeleton;

    return source;
  }

  static getSkeletonOffsets(target, source, [options]) {
    options = options ?? {};

    var targetParentPos = Vector3(),
        targetPos = Vector3(),
        sourceParentPos = Vector3(),
        sourcePos = Vector3(),
        targetDir = Vector2(),
        sourceDir = Vector2();

    options.hip = options.hip ?? 'hip';
    options.names = options.names ?? {};

    if (!source.isObject3D) {
      source = getHelperFromSkeleton(source);
    }

    var nameKeys = options.names.keys,
        nameValues = options.names.values,
        sourceBones = source.isObject3D ? source.skeleton.bones : getBones(source),
        bones = target.isObject3D ? target.skeleton.bones : getBones(target),
        offsets = [];

    var bone, boneTo, name, i;

    target.skeleton.pose();

    for (i = 0; i < bones.length; ++i) {
      bone = bones[i];
      name = options.names[bone.name] || bone.name;

      boneTo = getBoneByName(name, sourceBones);

      if (boneTo && name != options.hip) {
        var boneParent = getNearestBone(bone.parent, nameKeys),
            boneToParent = getNearestBone(boneTo.parent, nameValues);

        boneParent.updateMatrixWorld();
        boneToParent.updateMatrixWorld();

        targetParentPos.setFromMatrixPosition(boneParent.matrixWorld);
        targetPos.setFromMatrixPosition(bone.matrixWorld);

        sourceParentPos.setFromMatrixPosition(boneToParent.matrixWorld);
        sourcePos.setFromMatrixPosition(boneTo.matrixWorld);

        targetDir
            .sub2(Vector2(targetPos.x, targetPos.y), Vector2(targetParentPos.x, targetParentPos.y))
            .normalize();

        sourceDir
            .sub2(Vector2(sourcePos.x, sourcePos.y), Vector2(sourceParentPos.x, sourceParentPos.y))
            .normalize();

        var laterialAngle = targetDir.angle() - sourceDir.angle();

        var offset = Matrix4().makeRotationFromEuler(Euler(0, 0, laterialAngle));

        bone.matrix.multiply(offset);

        bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);

        bone.updateMatrixWorld();

        offsets[name] = offset;
      }
    }

    return offsets;
  }

  static renameBones(skeleton, names) {
    var bones = getBones(skeleton);

    for (var i = 0; i < bones.length; ++i) {
      var bone = bones[i];

      if (names[bone.name]) {
        bone.name = names[bone.name];
      }
    }

    // TODO how return this;
    console.info("SkeletonUtils.renameBones need confirm how return this  ");

    // return this;
  }

  static getBones(skeleton) {
    return skeleton is List ? skeleton : skeleton.bones;
  }

  static getBoneByName(name, skeleton) {
    for (var i = 0, bones = getBones(skeleton); i < bones.length; i++) {
      if (name == bones[i].name) return bones[i];
    }
  }

  static getNearestBone(bone, names) {
    while (bone.isBone) {
      if (names.indexOf(bone.name) != -1) {
        return bone;
      }

      bone = bone.parent;
    }
  }

  static findBoneTrackData(name, tracks) {
    var regexp = RegExp(r"\[(.*)\]\.(.*)");

    var result = {"name": name};

    for (var i = 0; i < tracks.length; ++i) {
      // 1 is track name
      // 2 is track type
      var trackData = regexp.firstMatch(tracks[i].name);

      if (trackData != null && name == trackData.group(1)) {
        result[trackData.group(2)!] = i;
      }
    }

    return result;
  }

  static getEqualsBonesNames(skeleton, targetSkeleton) {
    var sourceBones = getBones(skeleton), targetBones = getBones(targetSkeleton), bones = [];

    search:
    for (var i = 0; i < sourceBones.length; i++) {
      var boneName = sourceBones[i].name;

      for (var j = 0; j < targetBones.length; j++) {
        if (boneName == targetBones[j].name) {
          bones.add(boneName);

          continue search;
        }
      }
    }

    return bones;
  }

  static clone(source) {
    var sourceLookup = {};
    var cloneLookup = {};

    var clone = source.clone();

    parallelTraverse(source, clone, (sourceNode, clonedNode) {
      // sourceLookup.set( clonedNode, sourceNode );
      // cloneLookup.set( sourceNode, clonedNode );

      sourceLookup[clonedNode] = sourceNode;
      cloneLookup[sourceNode] = clonedNode;
    });

    clone.traverse((node) {
      if (!node.runtimeType.toString().contains("SkinnedMesh")) return;

      var clonedMesh = node;
      var sourceMesh = sourceLookup[node];
      var sourceBones = sourceMesh.skeleton.bones;

      clonedMesh.skeleton = sourceMesh.skeleton.clone();
      clonedMesh.bindMatrix.setFrom(sourceMesh.bindMatrix);

      clonedMesh.skeleton.bones = List<Bone>.from(sourceBones.map((bone) {
        return cloneLookup[bone];
      }).toList());

      clonedMesh.bind(clonedMesh.skeleton, clonedMesh.bindMatrix);
    });

    return clone;
  }

  static parallelTraverse(a, b, callback) {
    callback(a, b);

    for (int i = 0; i < a.children.length; i++) {
      var _bc;

      if (b != null && i < b.children.length) {
        _bc = b.children[i];
      }

      parallelTraverse(a.children[i], _bc, callback);
    }
  }
}
