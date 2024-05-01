import 'package:flutter_gl/native-array/index.dart';
import 'package:three_js_core/others/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'animation_clip.dart';
import 'keyframe_track.dart';

/// An object with various functions to assist with animations, used internally.
class AnimationUtils {
  // same as Array.prototype.slice, but also works on typed arrays
  static List<T> arraySlice<T>(List<T> array, [int from = 0, int? to]) {
    // if ( AnimationUtils.isTypedArray( array ) ) {
    if (array.runtimeType.toString() != "List<num>") {
      console.info(" AnimationUtils.arraySlice array: ${array.runtimeType} ");
      // 	// in ios9 array.subarray(from, null) will return empty array
      // 	// but array.subarray(from) or array.subarray(from, len) is correct
      // 	return new array.constructor( array.subarray( from, to != null ? to : array.length ) );
    }

    return array.sublist(from, to);
  }

  /// Converts an array to a specific type.
  static List<num> convertArray(array, String type, [bool forceClone = false]) {
    // var 'null' and 'null' pass
    if (array == null || !forceClone && array.runtimeType.toString() == type) {
      return array;
    }

    if (array is NativeArray && type == 'List<num>') {
      return array.toDartList();
    }

    if (type == 'List<num>') {
      // create typed array
      return List<num>.from(array);
    }

    return array.sublist(0);//slice(array, 0); // create Array
  }

  /// Returns `true` if the object is a typed array.
  static bool isTypedArray(object) {
    console.info("AnimationUtils isTypedArray object: ${object.runtimeType}");
    return false;

    // return ArrayBuffer.isView( object ) &&
    // 	! ( object instanceof DataView );
  }

  /// Returns an array by which times and values can be sorted.
  static List<int> getKeyframeOrder(List<num> times) {
    int compareTime(int i, int j) {
      return (times[i] - times[j]).toInt();
    }

    int  n = times.length;
    List<int> result = List<int>.filled(n, 0);
    for (int i = 0; i != n; ++i) {
      result[i] = i;
    }

    result.sort((a, b) {
      return compareTime(a, b);
    });

    return result;
  }

  /// Sorts the array previously returned by [getKeyframeOrder].
  static List<num> sortedArray(List<num> values, int stride, List<int> order) {
    final nValues = values.length;
    final result = List<num>.filled(nValues, 0);

    for (int i = 0, dstOffset = 0; dstOffset != nValues; ++i) {
      int srcOffset = order[i] * stride;

      for (int j = 0; j != stride; ++j) {
        result[dstOffset++] = values[srcOffset + j];
      }
    }

    return result;
  }

  // function for parsing AOS keyframe formats
  // this does nothing in Dart
  // static void flattenJSON(List<String> jsonKeys, List<num> times, List<num> values, String valuePropertyName) {
    // int i = 1;
    // String key = jsonKeys[0];

    // while (key != null && key[valuePropertyName] == null) {
    //   key = jsonKeys[i++];
    // }

    // if (key == null) return; // no data

    // var value = key[valuePropertyName];
    // if (value == null) return; // no data

    // // if ( Array.isArray( value ) ) {
    // if (value.runtimeType.toString() == "List<num>") {
    //   do {
    //     value = key[valuePropertyName];

    //     if (value != null) {
    //       times.add(key.time);
    //       values.add.apply(values, value); // push all elements

    //     }

    //     key = jsonKeys[i++];
    //   } while (key != null);
    // } 
    // else if (value.toArray != null) {
    //   // ...assume THREE.Math-ish

    //   do {
    //     value = key[valuePropertyName];

    //     if (value != null) {
    //       times.add(key.time);
    //       value.toArray(values, values.length);
    //     }

    //     key = jsonKeys[i++];
    //   } while (key != null);
    // } 
    // else {
    //   do {
    //     value = key[valuePropertyName];

    //     if (value != null) {
    //       times.add(key.time);
    //       values.add(value);
    //     }

    //     key = jsonKeys[i++];
    //   } while (key != null);
    // }
  // }

  /// Creates a new clip, containing only the segment of the original clip between the given frames.
  AnimationClip subclip(AnimationClip sourceClip, String name, int startFrame, int endFrame, {int fps = 30}) {
    final clip = sourceClip.clone();

    clip.name = name;

    final List<KeyframeTrack> tracks = [];

    for (int i = 0; i < clip.tracks.length; ++i) {
      final track = clip.tracks[i];
      final valueSize = track.getValueSize();

      final times = [];
      final values = [];

      for (int j = 0; j < track.times.length; ++j) {
        final frame = track.times[j] * fps;

        if (frame < startFrame || frame >= endFrame) continue;

        times.add(track.times[j]);

        for (int k = 0; k < valueSize; ++k) {
          values.add(track.values[j * valueSize + k]);
        }
      }

      if (times.isEmpty) continue;

      track.times = AnimationUtils.convertArray(times, track.times.runtimeType.toString());
      track.values = AnimationUtils.convertArray(values, track.values.runtimeType.toString());

      tracks.add(track);
    }

    clip.tracks = tracks;

    // find minimum .times value across all tracks in the trimmed clip

    double minStartTime = double.infinity;

    for (int i = 0; i < clip.tracks.length; ++i) {
      if (minStartTime > clip.tracks[i].times[0]) {
        minStartTime = clip.tracks[i].times[0].toDouble();
      }
    }

    // shift all tracks such that clip begins at t=0

    for (int i = 0; i < clip.tracks.length; ++i) {
      clip.tracks[i].shift(-1 * minStartTime);
    }

    clip.resetDuration();

    return clip;
  }

  /// Converts the keyframes of the given animation clip to an additive format.
  AnimationClip makeClipAdditive(AnimationClip targetClip,{int referenceFrame = 0, AnimationClip? referenceClip, int fps = 30}) {
    referenceClip ??= targetClip;

    if (fps <= 0) fps = 30;

    final numTracks = referenceClip.tracks.length;
    final referenceTime = referenceFrame / fps;

    // Make each track's values relative to the values at the reference frame
    for (int i = 0; i < numTracks; ++i) {
      final referenceTrack = referenceClip.tracks[i];
      final referenceTrackType = referenceTrack.valueTypeName;

      // Skip this track if it's non-numeric
      if (referenceTrackType == 'bool' || referenceTrackType == 'string') {
        continue;
      }

      // Find the track in the target clip whose name and type matches the reference track
      KeyframeTrack? targetTrack = targetClip.tracks.firstWhere((track) {
        return track.name == referenceTrack.name && track.valueTypeName == referenceTrackType;
      });

      //if (targetTrack == null) continue;

      int referenceOffset = 0;
      final referenceValueSize = referenceTrack.getValueSize();

      console.info("AnimationUtils isInterpolantFactoryMethodGLTFCubicSpline todo");
      // if ( referenceTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline ) {
      // 	referenceOffset = referenceValueSize / 3;
      // }

      int targetOffset = 0;
      final targetValueSize = targetTrack.getValueSize();

      console.info("AnimationUtils isInterpolantFactoryMethodGLTFCubicSpline todo");
      // if ( targetTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline ) {
      // 	targetOffset = targetValueSize / 3;
      // }

      final lastIndex = referenceTrack.times.length - 1;
      late List<num> referenceValue;

      // Find the value to subtract out of the track
      if (referenceTime <= referenceTrack.times[0]) {
        // Reference frame is earlier than the first keyframe, so just use the first keyframe
        final startIndex = referenceOffset;
        final endIndex = referenceValueSize - referenceOffset;
        referenceValue = AnimationUtils.arraySlice<num>(
            referenceTrack.values, startIndex, endIndex);
      } else if (referenceTime >= referenceTrack.times[lastIndex]) {
        // Reference frame is after the last keyframe, so just use the last keyframe
        int startIndex =
            (lastIndex * referenceValueSize + referenceOffset).toInt();
        int endIndex =
            (startIndex + referenceValueSize - referenceOffset).toInt();
        referenceValue = AnimationUtils.arraySlice(
            referenceTrack.values, startIndex, endIndex);
      } else {
        // Interpolate to the reference value
        final interpolant = referenceTrack.createInterpolant!();
        final startIndex = referenceOffset;
        final endIndex = referenceValueSize - referenceOffset;
        interpolant.evaluate(referenceTime);
        referenceValue = AnimationUtils.arraySlice(
            interpolant.resultBuffer, startIndex, endIndex);
      }

      // Conjugate the quaternion
      if (referenceTrackType == 'quaternion') {
        final referenceQuat = Quaternion().fromNumArray(referenceValue).normalize().conjugate();
        referenceQuat.toNumArray(referenceValue);
      }

      // Subtract the reference value from all of the track values

      final numTimes = targetTrack.times.length;
      for (int j = 0; j < numTimes; ++j) {
        int valueStart = (j * targetValueSize + targetOffset).toInt();

        if (referenceTrackType == 'quaternion') {
          // Multiply the conjugate for quaternion track types
          Quaternion.multiplyQuaternionsFlat(targetTrack.values, valueStart,
              referenceValue, 0, targetTrack.values, valueStart);
        } else {
          final valueEnd = targetValueSize - targetOffset * 2;

          // Subtract each value for all other numeric track types
          for (int k = 0; k < valueEnd; ++k) {
            targetTrack.values[valueStart + k] -= referenceValue[k];
          }
        }
      }
    }

    targetClip.blendMode = AdditiveAnimationBlendMode;

    return targetClip;
  }
}
