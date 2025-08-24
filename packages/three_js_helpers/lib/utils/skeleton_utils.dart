import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_animations/three_js_animations.dart';
import '../skeleton_helper.dart';

class SkeletonUtilsOptions{
  SkeletonUtilsOptions({
    this.preserveBoneMatrix = true,
    this.preserveBonePositions = true,
    this.useTargetMatrix = false,
    this.useFirstFramePosition = false,
    this.fps = 30,
    this.hip = 'hip',
    this.localOffsets,
    Map<String,dynamic>? names,
    this.scale = 1,
    this.hipPosition,
    Vector3? hipInfluence,
    this.getBoneName,
    this.trim
  }){
    this.names = names ?? {};
    this.hipInfluence = hipInfluence ??  Vector3( 1, 1, 1 );
  }
  
  bool preserveBoneMatrix;
  bool preserveBonePositions;
  bool useTargetMatrix;
  bool useFirstFramePosition;
  int fps;
  String hip;
  double scale;
  Map<String,dynamic>? localOffsets;
  Map<String,dynamic> names = {};
  Vector3? hipPosition;
  late Vector3 hipInfluence;
  String Function(Bone)? getBoneName;
  List? trim;
}

class SkeletonUtils {
  static void retargetFromSkeleton(Object3D target, Skeleton source, [SkeletonUtilsOptions? options]) {
    retarget(target, source,options);
  }
  static void retargetFromObject(Object3D target, Object3D source, [SkeletonUtilsOptions? options]) {
    retarget(target, source,options);
  }
  static void retarget(Object3D target, source, [SkeletonUtilsOptions? options]) {
    final quat = Quaternion(),
        scale = Vector3(),
        relativeMatrix = Matrix4(),
        globalMatrix = Matrix4();

    options ??= SkeletonUtilsOptions();

    List<Bone> sourceBones = source is Object3D ? (source.skeleton?.bones ?? []) : getBones(source);
    List<Bone> bones = target.skeleton?.bones ?? [];
    Bone bone;
    String? name;
    Bone? boneTo;
    List<Vector3> bonesPosition = [];

    // reset bones

    // if (target is Object3D) {
      target.skeleton?.pose();
    // } 
    // else {
    //   options.useTargetMatrix = true;
    //   options.preserveMatrix = false;
    // }

    if ( options.preserveBonePositions ) {
      bonesPosition = [];

      for (int i = 0; i < bones.length; i ++ ) {
        bonesPosition.add( bones[ i ].position.clone() );
      }
    }

    if ( options.preserveBoneMatrix ) {
      target.updateMatrixWorld();
      target.matrixWorld.identity();

      for (int i = 0; i < target.children.length; ++ i ) {
        target.children[ i ].updateMatrixWorld( true );
      }
    }

    for (int i = 0; i < bones.length; ++ i ) {
      bone = bones[ i ];
      name = getBoneName( bone, options );

      boneTo = getBoneByNameList( name!, sourceBones );

      globalMatrix.setFrom( bone.matrixWorld );

      if ( boneTo != null) {
        boneTo.updateMatrixWorld();

        if ( options.useTargetMatrix ) {
          relativeMatrix.setFrom( boneTo.matrixWorld );
        } 
        else {
          relativeMatrix.setFrom( target.matrixWorld ).invert();
          relativeMatrix.multiply( boneTo.matrixWorld );
        }

        // ignore scale to extract rotation

        scale.setFromMatrixScale( relativeMatrix );
        relativeMatrix.scaleByVector( scale.setValues( 1 / scale.x, 1 / scale.y, 1 / scale.z ) );

        // apply to global matrix

        globalMatrix.makeRotationFromQuaternion( quat.setFromRotationMatrix( relativeMatrix ) );

        //if ( target is Object3D ) {
          if ( options.localOffsets != null) {
            if ( options.localOffsets![ bone.name ] ) {
              globalMatrix.multiply( options.localOffsets![ bone.name ] );
            }
          }
        //}

        globalMatrix.copyPosition( relativeMatrix );
      }

      if ( name == options.hip ) {
        globalMatrix.storage[ 12 ] *= options.scale * options.hipInfluence.x;
        globalMatrix.storage[ 13 ] *= options.scale * options.hipInfluence.y;
        globalMatrix.storage[ 14 ] *= options.scale * options.hipInfluence.z;

        if ( options.hipPosition != null ) {
          globalMatrix.storage[ 12 ] += options.hipPosition!.x * options.scale;
          globalMatrix.storage[ 13 ] += options.hipPosition!.y * options.scale;
          globalMatrix.storage[ 14 ] += options.hipPosition!.z * options.scale;
        }
      }

      if ( bone.parent != null) {
        bone.matrix.setFrom( bone.parent!.matrixWorld ).invert();
        bone.matrix.multiply( globalMatrix );
      } else {
        bone.matrix.setFrom( globalMatrix );
      }

      bone.matrix.decompose( bone.position, bone.quaternion, bone.scale );

      bone.updateMatrixWorld();
    }

    if ( options.preserveBonePositions ) {
      for (int i = 0; i < bones.length; ++ i ) {
        bone = bones[ i ];
        name = getBoneName( bone, options ) ?? bone.name;

        if ( name != options.hip ) {
          bone.position.setFrom( bonesPosition[ i ] );
        }
      }
    }

    if ( options.preserveBoneMatrix ) {
      target.updateMatrixWorld( true );
    }
  }

  static AnimationClip retargetClipFromSkeleton(Object3D target, Skeleton input, AnimationClip clip, [SkeletonUtilsOptions? options]) {
    return retargetClip(target, input, clip, options);
  }
  static AnimationClip retargetClipFromObject(Object3D target, input, AnimationClip clip, [SkeletonUtilsOptions? options]) {
    return retargetClip(target, input, clip, options);
  }

  static AnimationClip retargetClip(Object3D target, input, AnimationClip clip, [SkeletonUtilsOptions? options]) {
    late SkeletonHelper source;
    options = options ?? SkeletonUtilsOptions();

    options.useFirstFramePosition = options.useFirstFramePosition;
    options.fps = options.fps;
    options.names = options.names;

    if (input is Skeleton) {
      source = getHelperFromSkeleton(input);
    }
    else if(input is SkeletonHelper){
      source = input;
    }
    else{
      source = getHelperFromSkeleton(input.skeleton!);
    }

    final numFrames = (clip.duration * (options.fps / 1000) * 1000).round(),
        delta = clip.duration / ( numFrames - 1 ),
        convertedTracks = <KeyframeTrack>[],
        mixer = AnimationMixer(source),
        bones = target is SkeletonHelper?target.bones:getBones(target.skeleton),
        boneDatas = [];
        
    Vector3? positionOffset;
    Bone? bone, boneTo; 
    Map<String,dynamic>? boneData;
    String name;

    mixer.clipAction(clip)?.play();

    int start = 0, end = numFrames;

    if ( options.trim != null ) {
      start = ( options.trim![ 0 ] * options.fps ).round();
      end = math.min<int>( ( options.trim![ 1 ] * options.fps ).round(), numFrames ) - start;
      mixer.update( options.trim![ 0 ] );
    } 
    else {
      mixer.update( 0 );
    }

    source.updateMatrixWorld();

    //
    for (int frame = 0; frame < end; ++ frame ) {
      final time = frame * delta;

      retarget( target, source, options );

      for ( int j = 0; j < bones.length; ++ j ) {
        bone = bones[ j ];
        name = getBoneName( bone!, options ) ?? bone.name;
        boneTo = getBoneByName( name, source.skeleton! );

        if ( boneTo != null) {
          boneData = boneDatas[ j ] = boneDatas[ j ] ?? { bone: bone };

          if ( options.hip == name ) {
            if (boneData?['pos'] == null) {
              boneData?['pos'] = {
                'times': new Float32List( end ),
                'values': new Float32List( end * 3 )
              };
            }

            if ( options.useFirstFramePosition ) {
              if ( frame == 0 ) {
                positionOffset = bone.position.clone();
              }

              bone.position.sub( positionOffset! );
            }

            boneData?['pos']['times'][ frame ] = time;
            bone.position.copyIntoArray( boneData!['pos']['values'], frame * 3 );
          }

          if (boneData?['quat'] == null) {
            boneData?['quat'] = {
              'times': new Float32List( end ),
              'values': new Float32List( end * 4 )
            };
          }

          boneData?['quat']['times'][ frame ] = time;
          bone.quaternion.toArray( boneData!['quat']['values'], frame * 4 );
        }
      }

      if ( frame == end - 2 ) {
        // last mixer update before final loop iteration
        // make sure we do not go over or equal to clip duration
        mixer.update( delta - 0.0000001 );
      } else {
        mixer.update( delta );
      }
      source.updateMatrixWorld();
    }

    for (int i = 0; i < boneDatas.length; ++ i ) {
      boneData = boneDatas[ i ];
      if ( boneData != null) {
        if ( boneData['pos'] != null) {
          convertedTracks.add( new VectorKeyframeTrack(
            '.bones[${boneData['bone']['name']}].position',
            boneData['pos']['times'],
            boneData['pos']['values']
          ) );
        }

        convertedTracks.add( new QuaternionKeyframeTrack(
          '.bones[${boneData['bone']['name']}].quaternion',
          boneData['quat']['times'],
          boneData['quat']['values']
        ) );
      }
    }

    mixer.uncacheAction( clip );

    return AnimationClip( clip.name, - 1, convertedTracks );
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

      boneTo = getBoneByNameList(name, sourceBones);

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
  static String? getBoneName(Bone bone, SkeletonUtilsOptions options ) {
    if ( options.getBoneName != null ) {
      return options.getBoneName?.call( bone );
    }

    return options.names[ bone.name ];
  }
  static Bone? getBoneByName(String name, Skeleton skeleton) {
    final bones = getBones( skeleton );
    for (int i = 0; i < bones.length; i ++ ) {
      if ( name == bones[ i ].name ) return bones[ i ];
    }

    return null;
  }

  static Bone? getBoneByNameList(String name, List<Bone> bones) {
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
