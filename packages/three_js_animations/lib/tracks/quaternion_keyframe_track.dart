import 'package:three_js_math/three_js_math.dart';
import '../animations/keyframe_track.dart';
import '../interpolants/index.dart';

/// A Track of quaternion keyframe values.
class QuaternionKeyframeTrack extends KeyframeTrack {
  /// [name] - identifier for the KeyframeTrack.
  ///
  /// [times] - array of keyframe times.
  /// 
  /// [values] - values for the keyframes at the times specified.
  ///
  ///	[interpolation] - the type of interpolation to use. See
	/// [Animation Constants] for possible values. Default is
  /// [Animation InterpolateLinear].
  QuaternionKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    defaultInterpolation = InterpolateLinear;
    valueTypeName = 'quaternion';
  }

  /// The default interpolation type to use, [page:Animation InterpolateLinear].
  @override
  Interpolant interpolantFactoryMethodLinear(result) {
    return QuaternionLinearInterpolant(times, values, getValueSize(), result);
  }

  /// Returns a new [page:QuaternionLinearInterpolant QuaternionLinearInterpolant] based on the [page:KeyframeTrack.values values], [page:KeyframeTrack.times times] and
	/// [page:KeyframeTrack.valueSize valueSize] of the keyframes.
  @override
  Interpolant? interpolantFactoryMethodSmooth(result) {
    return null;
  }

  @override
  QuaternionKeyframeTrack clone(){
    return QuaternionKeyframeTrack(name, times, values);
  }
}
