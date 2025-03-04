import 'package:three_js_core/others/index.dart';
import 'package:three_js_math/three_js_math.dart';
import '../textures/index.dart';
import './bone.dart';
import 'dart:math' as math;

final _offsetMatrix = Matrix4.identity();

/// Use an array of [bones] to create a skeleton that can be used by
/// a [SkinnedMesh].
/// 
/// ```
/// // Create a simple "arm"
/// 
/// final bones = [];
/// 
/// final shoulder = Bone();
/// final elbow = Bone();
/// final hand = Bone();
/// 
/// shoulder.add( elbow );
/// elbow.add( hand );
/// 
/// bones.add( shoulder );
/// bones.add( elbow );
/// bones.add( hand );
/// 
/// shoulder.position.y = -5;
/// elbow.position.y = 0;
/// hand.position.y = 5;
/// 
/// final armSkeleton = Skeleton( bones );
/// ```
/// 
/// See the [SkinnedMesh] page for an example of usage with standard
/// [BufferGeometry].
class Skeleton {
  String uuid = MathUtils.generateUUID();
  late List<Bone> bones;
  late List<Matrix4> boneInverses;
  Float32Array? boneMatrices;
  DataTexture? boneTexture;
  late int boneTextureSize;
  double frame = -1;
  bool disposed = true;

  /// [bones] - The array of [bones]. Default is an empty
  /// array.
  /// 
  /// [boneInverses] - (optional) An array of [Matrix4s].
  ///  
  /// Creates a new [name].
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
    boneMatrices?.dispose();
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

  /// Generates the [page:.boneInverses boneInverses] array if not provided in
	/// the constructor.
  void calculateInverses() {
    boneInverses.length = 0;
    boneInverses.clear();

    for (int i = 0, il = bones.length; i < il; i++) {
      final inverse = Matrix4.identity();

      inverse..setFrom(bones[i].matrixWorld)..invert();
      boneInverses.add(inverse);
    }
  }

  /// Returns the skeleton to the base pose.
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

  /// Updates the [boneMatrices] and [boneTexture] 
  /// after changing the bones. This is called automatically by the
  /// [WebGLRenderer] if the skeleton is used with a [SkinnedMesh].
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
      _offsetMatrix.copyIntoArray(boneMatrices!.toList(), i * 16);
    }

    if (boneTexture != null) {
      boneTexture.needsUpdate = true;
    }
  }

  /// Returns a clone of this Skeleton object.
  Skeleton clone() {
    return Skeleton(bones, boneInverses);
  }

  /// Computes an instance of [DataTexture] in order to pass the bone data
  /// more efficiently to the shader. The texture is assigned to
  /// [boneTexture].
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

  /// [name] - String to match to the Bone's .name property.
  /// 
  /// Searches through the skeleton's bone array and returns the first with a
  /// matching name.
  Bone? getBoneByName(String name) {
    for (int i = 0, il = bones.length; i < il; i++) {
      final bone = bones[i];

      if (bone.name == name) {
        return bone;
      }
    }

    return null;
  }

  /// Frees the GPU-related resources allocated by this instance. Call this
  /// method whenever this instance is no longer used in your app.
  void dispose() {
    if(disposed) return;
    disposed = true;
    boneTexture?.dispose();
    boneMatrices?.dispose();

    bones.forEach((bone){
      bone.dispose();
    });
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
      return boneMatrices!;
    } else {
      throw("Skeleton getValue name: $name is not support  ");
    }
  }
}
