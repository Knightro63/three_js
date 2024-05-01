import '../animations/keyframe_track.dart';

/// A Track of numeric keyframe values.
class NumberKeyframeTrack extends KeyframeTrack {
  /// [name] - identifier for the KeyframeTrack.
  ///
  /// [times] - array of keyframe times.
  /// 
  /// [values] - values for the keyframes at the times specified.
  ///
  ///	[interpolation] - the type of interpolation to use. See
	/// [Animation Constants] for possible values. Default is
  /// [Animation InterpolateLinear].
  NumberKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    valueTypeName = "number";
  }
  @override
  NumberKeyframeTrack clone(){
    return NumberKeyframeTrack(name, times, values);
  }
}
