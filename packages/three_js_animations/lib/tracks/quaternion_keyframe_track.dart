import 'package:three_js_math/three_js_math.dart';
import '../animations/keyframe_track.dart';
import '../interpolants/index.dart';

/// A Track of quaternion keyframe values.
class QuaternionKeyframeTrack extends KeyframeTrack {
  QuaternionKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    defaultInterpolation = InterpolateLinear;
    valueTypeName = 'quaternion';
  }

  @override
  Interpolant interpolantFactoryMethodLinear(result) {
    return QuaternionLinearInterpolant(times, values, getValueSize(), result);
  }

  @override
  Interpolant? interpolantFactoryMethodSmooth(result) {
    return null;
  }

  @override
  QuaternionKeyframeTrack clone(){
    return QuaternionKeyframeTrack(name, times, values);
  }
}
