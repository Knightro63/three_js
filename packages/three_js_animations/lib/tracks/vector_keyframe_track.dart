import '../animations/keyframe_track.dart';

/// A Track of vectored keyframe values.
class VectorKeyframeTrack extends KeyframeTrack {
  /// [name] - identifier for the KeyframeTrack.
  ///
  /// [times] - array of keyframe times.
  /// 
  /// [values] - values for the keyframes at the times specified.
  ///
  ///	[interpolation] - the type of interpolation to use. See
	/// [Animation Constants] for possible values. Default is
  /// [Animation InterpolateLinear].
  VectorKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    valueTypeName = 'vector';
  }

  @override
  VectorKeyframeTrack clone(){
    return VectorKeyframeTrack(name, times, values);
  }
}
