import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/others/index.dart';
import 'package:three_js_math/three_js_math.dart';
import '../textures/index.dart';
import './bone.dart';
import 'dart:math' as math;

final _offsetMatrix = Matrix4.identity();
final _identityMatrix = Matrix4.identity();

class Skeleton {
  String uuid = MathUtils.generateUUID();
  late List<Bone> bones;
  late List<Matrix4> boneInverses;
  late Float32Array boneMatrices;
  DataTexture? boneTexture;
  late int boneTextureSize;
  double frame = -1;

  Skeleton([List<Bone>? bones, List<Matrix4>? boneInverses]) {
    this.bones = bones!.sublist(0);
    this.boneInverses = boneInverses ?? [];

    init();
  }

  void init() {
    final bones = this.bones;
    final boneInverses = this.boneInverses;

    // layout (1 matrix = 4 pixels)
    //      RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
    //  with  8x8  pixel texture max   16 bones * 4 pixels =  (8 * 8)
    //       16x16 pixel texture max   64 bones * 4 pixels = (16 * 16)
    //       32x32 pixel texture max  256 bones * 4 pixels = (32 * 32)
    //       64x64 pixel texture max 1024 bones * 4 pixels = (64 * 64)

    double getSize = math.sqrt(bones.length * 4); // 4 pixels needed for 1 matrix
    getSize = MathUtils.ceilPowerOfTwo(getSize).toDouble();
    getSize = math.max(getSize, 4);

    int size = getSize.toInt();

    boneTextureSize = size;

    boneMatrices = Float32Array(size * size * 4);

    // calculate inverse bone matrices if necessary

    if (boneInverses.isEmpty) {
      calculateInverses();
    } 
    else {
      // handle special case

      if (bones.length != boneInverses.length) {
        console.warning('Skeleton: Number of inverse bone matrices does not match amount of bones.');

        this.boneInverses = [];

        for (int i = 0, il = this.bones.length; i < il; i++) {
          this.boneInverses.add(Matrix4.identity());
        }
      }
    }
  }

  void calculateInverses() {
    boneInverses.length = 0;
    boneInverses.clear();

    for (int i = 0, il = bones.length; i < il; i++) {
      final inverse = Matrix4.identity();

      inverse..setFrom(bones[i].matrixWorld)..invert();
      boneInverses.add(inverse);
    }
  }

  void pose() {
    // recover the bind-time world matrices

    for (int i = 0, il = bones.length; i < il; i++) {
      final bone = bones[i];
      bone.matrixWorld..setFrom(boneInverses[i])..invert();
    }

    // compute the local matrices, positions, rotations and scales

    for (int i = 0, il = bones.length; i < il; i++) {
      final bone = bones[i];
      if (bone.parent != null && bone.parent is Bone) {
        bone.matrix..setFrom(bone.parent!.matrixWorld)..invert();
        bone.matrix.multiply(bone.matrixWorld);
      } else {
        bone.matrix.setFrom(bone.matrixWorld);
      }

      bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
    }
  }

  void update() {
    final bones = this.bones;
    final boneInverses = this.boneInverses;
    final boneMatrices = this.boneMatrices;
    final boneTexture = this.boneTexture;

    // flatten bone matrices to array
    int il = bones.length;
    for (int i = 0; i < il; i++) {
      // compute the offset between the current and the original transform

      final matrix = bones[i].matrixWorld;

      _offsetMatrix.multiply2(matrix, boneInverses[i]);
      _offsetMatrix.copyIntoArray(boneMatrices.toDartList(), i * 16);
    }

    if (boneTexture != null) {
      boneTexture.needsUpdate = true;
    }
  }

  Skeleton clone() {
    return Skeleton(bones, boneInverses);
  }

  Skeleton computeBoneTexture() {

    boneTexture = DataTexture(boneMatrices, boneTextureSize, boneTextureSize,
        RGBAFormat, FloatType);

    boneTexture!.name = "DataTexture from Skeleton.computeBoneTexture";
    boneTexture!.needsUpdate = true;
    
    // Android Float Texture need NearestFilter
    boneTexture!.magFilter = NearestFilter;
    boneTexture!.minFilter = NearestFilter;

    return this;
  }

  Bone? getBoneByName(String name) {
    for (int i = 0, il = bones.length; i < il; i++) {
      final bone = bones[i];

      if (bone.name == name) {
        return bone;
      }
    }

    return null;
  }

  void dispose() {
    if (boneTexture != null) {
      boneTexture!.dispose();

      boneTexture = null;
    }
  }

  Skeleton fromJson(Map<String,dynamic> json, Map<String,Bone?> bones) {
    uuid = json['uuid'];

    for (int i = 0, l = json['bones'].length; i < l; i++) {
      final uuid = json['bones'][i];
      Bone? bone = bones[uuid];

      if (bone == null) {
        console.warning('Skeleton: No bone found with UUID: $uuid');
        bone = Bone();
      }

      this.bones.add(bone);
      boneInverses.add(Matrix4.identity()..copyFromArray(json['boneInverses'][i]));
    }

    init();

    return this;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      "metadata": {
        "version": 4.5,
        "type": 'Skeleton',
        "generator": 'Skeleton.toJson'
      },
      "bones": [],
      "boneInverses": []
    };

    data["uuid"] = uuid;

    final bones = this.bones;
    final boneInverses = this.boneInverses;

    for (int i = 0, l = bones.length; i < l; i++) {
      final bone = bones[i];
      data["bones"].add(bone.uuid);

      final boneInverse = boneInverses[i];
      data["boneInverses"].add(boneInverse.storage.toList());
    }

    return data;
  }

  Float32Array getValue(String name) {
    if(name == "boneMatrices") {
      return boneMatrices;
    } else {
      throw("Skeleton getValue name: $name is not support  ");
    }
  }
}
