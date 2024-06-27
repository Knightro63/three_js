import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'animation_utils.dart';
import 'keyframe_track.dart';
import '../tracks/index.dart';
import 'dart:math' as math;

/// An [AnimationClip] is a reusable set of keyframe tracks which represent an
/// animation.
/// 
/// For an overview of the different elements of the three.js animation system
/// see the "Animation System" article in the "Next Steps" section of the
// manual.
class AnimationClip {
  late String name;
  late String uuid;
  late num duration;
  late int blendMode;
  late List<KeyframeTrack> tracks;
  late List results;

  /// [name] - a name for this clip.
  /// 
  /// [duration] - the duration of this clip (in seconds). If a
  /// negative value is passed, the duration will be calculated from the passed
  /// `tracks` array.
  /// 
  /// [tracks] - an array of [KeyframeTracks].
  /// 
  /// [blendMode] - defines how the animation is blended/combined
  /// when two or more animations are simultaneously played.
  /// 
  /// Note: Instead of instantiating an AnimationClip directly with the
  /// constructor, you can use one of its static methods to create
  /// AnimationClips: from JSON ([parse]), from morph target
  /// sequences ([createFromMorphTargetSequence], 
  /// [createClipsFromMorphTargetSequences]) or from animation hierarchies
  /// ([parseAnimation]) - if your model doesn't already
  /// hold AnimationClips in its geometry's animations array.
  AnimationClip(this.name,[this.duration = -1, List<KeyframeTrack>? tracks, this.blendMode = NormalAnimationBlendMode]) {
    this.tracks = tracks ?? [];

    uuid = MathUtils.generateUUID();

    // this means it should figure out its duration by scanning the tracks
    if (duration < 0) {
      resetDuration();
    }
  }

  /// Sets the [duration] of the clip to the duration of its
  /// longest [KeyframeTrack].
  AnimationClip resetDuration() {
    final tracks = this.tracks;
    num duration = 0;

    for (int i = 0, n = tracks.length; i != n; ++i) {
      final track = this.tracks[i];

      duration = math.max(duration, track.times[track.times.length - 1]);
    }

    this.duration = duration;

    return this;
  }

  /// Trims all tracks to the clip's duration.
  AnimationClip trim() {
    for (int i = 0; i < tracks.length; i++) {
      tracks[i].trim(0, duration);
    }

    return this;
  }

  /// Performs minimal validation on each track in the clip. Returns true if all
	/// tracks are valid.
  bool validate() {
    bool valid = true;

    for (int i = 0; i < tracks.length; i++) {
      valid = valid && tracks[i].validate();
    }

    return valid;
  }

  /// Optimizes each track by removing equivalent sequential keys (which are
	/// common in morph target sequences).
  AnimationClip optimize() {
    for (int i = 0; i < tracks.length; i++) {
      tracks[i].optimize();
    }

    return this;
  }
  
  /// Returns a copy of this clip.
  AnimationClip clone() {
    final List<KeyframeTrack> tracks = [];

    for (int i = 0; i < this.tracks.length; i++) {
      tracks.add(this.tracks[i].clone());
    }

    return AnimationClip(name, duration, tracks, blendMode);
  }

  /// Returns a JSON object representing the serialized animation clip.
  Map<String,dynamic> toJson() {
    return AnimationClip.toJsonStatic(this);
  }

  // Parses a JSON representation of a clip and returns an AnimationClip.
  static AnimationClip parse(Map<String,dynamic> json) {
    final List<KeyframeTrack> tracks = [];

    final List jsonTracks = json['tracks'];
    double frameTime = 1.0 / (json['fps'] ?? 1.0);

    for (int i = 0, n = jsonTracks.length; i != n; ++i) {
      tracks.add(parseKeyframeTrack(jsonTracks[i]).scale(frameTime));
    }

    AnimationClip clip = AnimationClip(json['name'], json['duration'], tracks, json['blendMode']);
    clip.uuid = json['uuid'];

    return clip;
  }

  static Map<String,dynamic> toJsonStatic(AnimationClip clip) {
    final tracks = [], clipTracks = clip.tracks;

    final json = {
      'name': clip.name,
      'duration': clip.duration,
      'tracks': tracks,
      'uuid': clip.uuid,
      'blendMode': clip.blendMode
    };

    for (int i = 0, n = clipTracks.length; i != n; ++i) {
      tracks.add(KeyframeTrack.toJson(clipTracks[i]));
    }

    return json;
  }

  /// Returns an array of new AnimationClips created from the morph target
	/// sequences of a geometry, trying to sort morph target names into
	/// animation-group-based patterns like "Walk_001, Walk_002, Run_001, Run_002...".
  static AnimationClip createFromMorphTargetSequence(
    String name, 
    List<MorphTarget> morphTargetSequence, 
    int fps, 
    bool noLoop
  ) {
    final numMorphTargets = morphTargetSequence.length;
    final List<KeyframeTrack> tracks = [];

    for (int i = 0; i < numMorphTargets; i++) {
      List<num> times = [];
      List<num> values = [];

      times.addAll([
        (i + numMorphTargets - 1) % numMorphTargets,
        i,
        (i + 1) % numMorphTargets
      ]);

      values.addAll([0, 1, 0]);

      final order = AnimationUtils.getKeyframeOrder(times);
      times = AnimationUtils.sortedArray(times, 1, order);
      values = AnimationUtils.sortedArray(values, 1, order);

      // if there is a key at the first frame, duplicate it as the
      // last frame as well for perfect loop.
      if (!noLoop && times[0] == 0) {
        times.add(numMorphTargets);
        values.add(values[0]);
      }

      tracks.add(NumberKeyframeTrack('.morphTargetInfluences[${morphTargetSequence[i].name}]',times,values).scale(1.0 / fps));
    }

    return AnimationClip(name, -1, tracks);
  }

  /// Searches for an AnimationClip by name, taking as its first parameter
  /// either an array of AnimationClips, or a mesh or geometry that contains an
  /// array named "animations".
  static AnimationClip? findByName(List<AnimationClip> objectOrClipArray, String name) {
    final clipArray = objectOrClipArray;

    for (int i = 0; i < clipArray.length; i++) {
      if (clipArray[i].name == name) {
        return clipArray[i];
      }
    }

    return null;
  }

  /// Returns a new AnimationClip from the passed morph targets array of a
  /// geometry, taking a name and the number of frames per second.
  /// 
	//// Note: The fps parameter is required, but the animation speed can be
	/// overridden in an `AnimationAction` via [animationAction.setDuration].
  static List<AnimationClip> createClipsFromMorphTargetSequences(List<MorphTarget> morphTargets, int fps, [bool noLoop = false]) {
    final Map<String,List<MorphTarget>> animationToMorphTargets = {};

    // tested with https://regex101.com/ on trick sequences
    // such flamingo_flyA_003, flamingo_run1_003, crdeath0059
    RegExp pattern = RegExp(r"^([\w-]*?)([\d]+)$");

    // sort morph target names into animation groups based
    // patterns like Walk_001, Walk_002, Run_001, Run_002
    for (final morphTarget in morphTargets) {
      final parts = pattern.allMatches(morphTarget.name);
      if(parts.isNotEmpty){
        final name = parts.first.group(1)!;

        List<MorphTarget>? animationMorphTargets = animationToMorphTargets[name];

        if (animationMorphTargets == null) {
          animationToMorphTargets[name] = animationMorphTargets = [];
        }

        animationMorphTargets.add(morphTarget);
      }
    }

    List<AnimationClip> clips = [];

    // for ( String name in animationToMorphTargets ) {
    animationToMorphTargets.forEach((name, value) {
      if(animationToMorphTargets[name] != null){
        clips.add(AnimationClip.createFromMorphTargetSequence(name, animationToMorphTargets[name]!, fps, noLoop));
      }
    });

    return clips;
  }

  // parse the animation.hierarchy format
  static AnimationClip? parseAnimation(Map<String,dynamic>? animation, bones) {
    if (animation == null) {
      console.warning('AnimationClip: No animation in JsonLoader data.');
      return null;
    }

    void addNonemptyTrack(String trackType, String trackName, List<String> animationKeys, String propertyName, List<KeyframeTrack> destTracks) {
      // only return track if there are actually keys.
      if (animationKeys.isNotEmpty) {
        final List<double> times = [];
        final List<double> values = [];

        //AnimationUtils.flattenJSON(animationKeys, times, values, propertyName);

        // empty keys are filtered out, so check again
        if (times.isNotEmpty) {
          if (trackType == "VectorKeyframeTrack") {
            destTracks.add(VectorKeyframeTrack(trackName, times, values, null));
          } 
          else if (trackType == "QuaternionKeyframeTrack") {
            destTracks.add(QuaternionKeyframeTrack(trackName, times, values, null));
          } 
          else {
            throw ("AnimationClip. addNonemptyTrack trackType: $trackType is not support ");
          }
        }
      }
    }

    final List<KeyframeTrack> tracks = [];

    String clipName = animation['name'] ?? 'default';
    int fps = animation['fps'] ?? 30;
    int blendMode = animation['blendMode'];

    // automatic length determination in AnimationClip.
    num duration = animation['length'] ?? -1;

    final hierarchyTracks = animation['hierarchy'] ?? [];

    for (int h = 0; h < hierarchyTracks.length; h++) {
      final animationKeys = hierarchyTracks[h].keys;

      // skip empty tracks
      if (!animationKeys || animationKeys.length == 0) continue;

      // process morph targets
      if (animationKeys[0].morphTargets) {
        // figure out all morph targets used in this track
        final morphTargetNames = {};

        int k;

        for (k = 0; k < animationKeys.length; k++) {
          if (animationKeys[k].morphTargets) {
            for (int m = 0; m < animationKeys[k].morphTargets.length; m++) {
              morphTargetNames[animationKeys[k].morphTargets[m]] = -1;
            }
          }
        }

        // create a track for each morph target with all zero
        // morphTargetInfluences except for the keys in which
        // the morphTarget is named.
        // for ( String morphTargetName in morphTargetNames ) {
        morphTargetNames.forEach((morphTargetName, value) {
          List<num> times = [];
          List<num> values = [];

          for (int m = 0; m != animationKeys[k].morphTargets.length; ++m) {
            final animationKey = animationKeys[k];

            times.add(animationKey.time);
            values.add((animationKey.morphTarget == morphTargetName) ? 1 : 0);
          }

          tracks.add(NumberKeyframeTrack('.morphTargetInfluence[$morphTargetName]',times,values,null));
        });

        duration = morphTargetNames.length * fps;
      } 
      else {
        // ...assume skeletal animation

        String boneName = '.bones[${bones[h].name}]';

        addNonemptyTrack("VectorKeyframeTrack",  '$boneName.position',
            animationKeys, 'pos', tracks);

        addNonemptyTrack("QuaternionKeyframeTrack", '$boneName.quaternion',
            animationKeys, 'rot', tracks);

        addNonemptyTrack("VectorKeyframeTrack", '$boneName.scale',
            animationKeys, 'scl', tracks);
      }
    }

    if (tracks.isEmpty) {
      return null;
    }

    AnimationClip clip = AnimationClip(clipName, duration, tracks, blendMode);

    return clip;
  }
}

String getTrackTypeForValueTypeName(typeName) {
  switch (typeName.toLowerCase()) {
    case 'scalar':
    case 'double':
    case 'float':
    case 'number':
    case 'integer':
      return "NumberKeyframeTrack";

    case 'vector':
    case 'vector2':
    case 'vector3':
    case 'vector4':
      return "VectorKeyframeTrack";

    case 'color':
      return "ColorKeyframeTrack";

    case 'quaternion':
      return "QuaternionKeyframeTrack";

    case 'bool':
    case 'boolean':
      return "BooleanKeyframeTrack";

    case 'string':
      return "StringKeyframeTrack";
  }

  throw ('THREE.KeyframeTrack: Unsupported typeName: $typeName');
}

KeyframeTrack parseKeyframeTrack(Map<String,dynamic> json) {
  if (json['type'] == null) {
    throw ('THREE.KeyframeTrack: track type undefined, can not parse');
  }

  final trackType = getTrackTypeForValueTypeName(json['type']);

  if (json['times'] == null) {
    final List<num> times = [];
    final List<num> values = [];

    //AnimationUtils.flattenJSON(json.keys.toList(), times, values, 'value');

    json['times'] = times;
    json['values'] = values;
  }

  // derived classes can define a static parse method
  // if ( trackType.parse != null ) {
  // 	return trackType.parse( json );
  // } else {
  // 	// by default, we assume a constructor compatible with the base
  // 	return new trackType( json['name'], json['times'], json['values'], json['interpolation'] );
  // }

  if (trackType == "NumberKeyframeTrack") {
    return NumberKeyframeTrack(
        json['name'], json['times'], json['values'], json['interpolation']);
  } else if (trackType == "VectorKeyframeTrack") {
    return VectorKeyframeTrack(
        json['name'], json['times'], json['values'], json['interpolation']);
  } else if (trackType == "ColorKeyframeTrack") {
    return ColorKeyframeTrack(
        json['name'], json['times'], json['values'], json['interpolation']);
  } else if (trackType == "QuaternionKeyframeTrack") {
    return QuaternionKeyframeTrack(
        json['name'], json['times'], json['values'], json['interpolation']);
  } else if (trackType == "BooleanKeyframeTrack") {
    return BooleanKeyframeTrack(
        json['name'], json['times'], json['values'], json['interpolation']);
  } else if (trackType == "StringKeyframeTrack") {
    return StringKeyframeTrack(
        json['name'], json['times'], json['values'], json['interpolation']);
  } else {
    throw ("AnimationClip.parseKeyframeTrack trackType: $trackType ");
  }
}
