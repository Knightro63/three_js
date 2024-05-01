import '../animations/keyframe_track.dart';

/// A Track of keyframe values that represent color.
class ColorKeyframeTrack extends KeyframeTrack {
  /// [name] - identifier for the KeyframeTrack.
  ///
  /// [times] - array of keyframe times.
  /// 
  /// [values] - values for the keyframes at the times specified.
  ///
  ///	[interpolation] - the type of interpolation to use. See
	/// [Animation Constants] for possible values. Default is
  /// [Animation InterpolateLinear].
  ColorKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    valueTypeName = 'color';
  }

  @override
  ColorKeyframeTrack clone(){
    return ColorKeyframeTrack(name, times, values);
  }
}
