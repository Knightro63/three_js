import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'animation_utils.dart';
import 'dart:math' as math;
import '../interpolants/index.dart';

class KeyframeTrack {
  late String name;
  late List<num> times;
  late List<num> values;

  String timeBufferType = "List<num>";
  String valueBufferType = "List<num>";
  int defaultInterpolation = InterpolateLinear;
  late String valueTypeName;

  Function? createInterpolant;
  late int? _interpolation;

  KeyframeTrack(this.name,List<num> times,List<num> values, [int? interpolation]) {
    // if (name == null) throw ('THREE.KeyframeTrack: track name is null');
    // this.name = name;
    // if (times == null || times.isEmpty) throw ('THREE.KeyframeTrack: no keyframes in track named $name');
    this.times = AnimationUtils.convertArray(times, timeBufferType, false);
    
    _interpolation = interpolation;
    
    this.values = AnimationUtils.convertArray(values, valueBufferType, false);

    setInterpolation(_interpolation ?? defaultInterpolation);
  }

  // Serialization (in static context, because of constructor invocation
  // and automatic invocation of .toJSON):

  static Map<String,dynamic> toJson(KeyframeTrack track) {
    //final trackType = track;

    Map<String,dynamic> json = {};

    // derived classes can define a static toJSON method
    // if (trackType.toJSON != null) {
    //   json = trackType.toJSON(track);
    // } 
    // else {
      // by default, we assume the data can be serialized as-is
      json = {
        'name': track.name,
        'times': AnimationUtils.convertArray(track.times, "List<num>"),
        'values': AnimationUtils.convertArray(track.values, "List<num>")
      };

      final int? interpolation = track.getInterpolation();

      if (interpolation != track.defaultInterpolation) {
        json['interpolation'] = interpolation;
      }
    //}

    json['type'] = track.valueTypeName; // mandatory

    return json;
  }


  Interpolant? interpolantFactoryMethodDiscrete(result) {
    return DiscreteInterpolant(
      times, 
      values, 
      getValueSize(), 
      result
    );
  }

  Interpolant? interpolantFactoryMethodLinear(result) {
    return LinearInterpolant(
      times, 
      values, 
      getValueSize(), 
      result
    );
  }

  Interpolant? interpolantFactoryMethodSmooth(result) {
    return CubicInterpolant(times, values, getValueSize(), result);
  }

  KeyframeTrack setInterpolation(int interpolation) {
    Function(dynamic result)? factoryMethod;

    switch (interpolation) {
      case InterpolateDiscrete:
        factoryMethod = interpolantFactoryMethodDiscrete;
        break;
      case InterpolateLinear:
        factoryMethod = interpolantFactoryMethodLinear;
        break;
      case InterpolateSmooth:
        factoryMethod = interpolantFactoryMethodSmooth;
        break;
    }

    if (factoryMethod == null) {
      final message = 'unsupported interpolation for $valueTypeName keyframe track named $name';

      if (createInterpolant == null) {
        // fall back to default, unless the default itself is messed up
        if (interpolation != defaultInterpolation) {
          setInterpolation(defaultInterpolation);
        } else {
          throw (message); // fatal, in this case

        }
      }

      console.info('KeyframeTrack: $message');
      return this;
    }

    createInterpolant = factoryMethod;

    return this;
  }

  int? getInterpolation() {
    console.info("KeyframeTrack.getInterpolation todo debug need confirm?? ");
    return _interpolation;
  }

  int getValueSize() {
    return values.length ~/ times.length;
  }

  // move all keyframes either forwards or backwards in time
  KeyframeTrack shift(timeOffset) {
    if (timeOffset != 0.0) {
      final times = this.times;

      for (int i = 0, n = times.length; i != n; ++i) {
        times[i] += timeOffset;
      }
    }

    return this;
  }

  // scale all keyframe times by a factor (useful for frame <-> seconds conversions)
  KeyframeTrack scale(timeScale) {
    if (timeScale != 1.0) {
      final times = this.times;

      for (int i = 0, n = times.length; i != n; ++i) {
        times[i] *= timeScale;
      }
    }

    return this;
  }

  // removes keyframes before and after animation without changing any values within the range [startTime, endTime].
  // IMPORTANT: We do not shift around keys to the start of the track time, because for interpolated keys this will change their values
  KeyframeTrack trim(startTime, endTime) {
    final times = this.times, nKeys = times.length;

    int from = 0, to = nKeys - 1;

    while (from != nKeys && times[from] < startTime) {
      ++from;
    }

    while (to != -1 && times[to] > endTime) {
      --to;
    }

    ++to; // inclusive -> exclusive bound

    if (from != 0 || to != nKeys) {
      // empty tracks are forbidden, so keep at least one keyframe
      if (from >= to) {
        to = math.max(to, 1).toInt();
        from = to - 1;
      }

      final stride = getValueSize();
      this.times = AnimationUtils.arraySlice(times, from, to);
      values = AnimationUtils.arraySlice(
          values, (from * stride).toInt(), (to * stride).toInt());
    }

    return this;
  }

  // ensure we do not get a GarbageInGarbageOut situation, make sure tracks are at least minimally viable
  bool validate() {
    bool valid = true;

    final valueSize = getValueSize();
    if (valueSize - valueSize.floor() != 0) {
      console.warning('KeyframeTrack: Invalid value size in track. $this');
      valid = false;
    }

    final times = this.times, values = this.values, nKeys = times.length;

    if (nKeys == 0) {
      console.warning('KeyframeTrack: Track is empty. $this');
      valid = false;
    }

    num? prevTime;

    for (int i = 0; i != nKeys; i++) {
      final currTime = times[i];

      if (currTime.isNaN) {
        console.warning('KeyframeTrack: Time is not a valid number. $this i: $i $currTime');
        valid = false;
        break;
      }
      
      if (prevTime != null && prevTime > currTime) {
        console.warning('KeyframeTrack: Out of order keys.$this i: $i currTime: $currTime prevTime: $prevTime');
        valid = false;
        break;
      }
      prevTime = currTime;
    }

    if (AnimationUtils.isTypedArray(values)) {
      for (int i = 0, n = values.length; i != n; ++i) {
        final value = values[i];

        if (value.isNaN) {
          console.warning('KeyframeTrack: Value is not a valid number. $this i: $i value: $value');
          valid = false;
          break;
        }
      }
    }

    return valid;
  }

  // removes equivalent sequential keys as common in morph target sequences
  // (0,0,0,0,1,1,1,0,0,0,0,0,0,0) --> (0,0,1,1,0,0)
  KeyframeTrack optimize() {
    // times or values may be shared with other tracks, so overwriting is unsafe
    final times = AnimationUtils.arraySlice(this.times),
        values = AnimationUtils.arraySlice(this.values),
        stride = getValueSize(),
        smoothInterpolation = getInterpolation() == InterpolateSmooth,
        lastIndex = times.length - 1;

    int writeIndex = 1;

    for (int i = 1; i < lastIndex; ++i) {
      bool keep = false;

      final time = times[i];
      final timeNext = times[i + 1];

      // remove adjacent keyframes scheduled at the same time

      if (time != timeNext && (i != 1 || time != times[0])) {
        if (!smoothInterpolation) {
          // remove unnecessary keyframes same as their neighbors

          final offset = i * stride,
              offsetP = offset - stride,
              offsetN = offset + stride;

          for (int j = 0; j != stride; ++j) {
            final value = values[offset + j];

            if (value != values[offsetP + j] || value != values[offsetN + j]) {
              keep = true;
              break;
            }
          }
        } else {
          keep = true;
        }
      }

      // in-place compaction

      if (keep) {
        if (i != writeIndex) {
          times[writeIndex] = times[i];

          final readOffset = i * stride, writeOffset = writeIndex * stride;

          for (int j = 0; j != stride; ++j) {
            values[writeOffset + j] = values[readOffset + j];
          }
        }

        ++writeIndex;
      }
    }

    // flush last keyframe (compaction looks ahead)

    if (lastIndex > 0) {
      times[writeIndex] = times[lastIndex];

      for (int readOffset = lastIndex * stride,
              writeOffset = writeIndex * stride,
              j = 0;
          j != stride;
          ++j) {
        values[writeOffset + j] = values[readOffset + j];
      }

      ++writeIndex;
    }

    if (writeIndex != times.length) {
      this.times = AnimationUtils.arraySlice(times, 0, writeIndex);
      this.values = AnimationUtils.arraySlice(values, 0, (writeIndex * stride).toInt());
    } else {
      this.times = times;
      this.values = values;
    }

    return this;
  }

  KeyframeTrack clone() {
    return KeyframeTrack(name, times, values)..createInterpolant = createInterpolant;
  }
}
