import 'package:three_js_math/three_js_math.dart';
import '../animations/keyframe_track.dart';
import '../interpolants/interpolant.dart';

/// A Track that interpolates Strings
class StringKeyframeTrack extends KeyframeTrack {
  /// [name] - identifier for the KeyframeTrack.
  ///
  /// [times] - array of keyframe times.
  /// 
  /// [values] - values for the keyframes at the times specified.
  ///
  ///	[interpolation] - the type of interpolation to use. See
	/// [Animation Constants] for possible values. Default is
  /// [Animation InterpolateLinear].
  StringKeyframeTrack(super.name,super.times,super.values, [super.interpolation]){
    defaultInterpolation = InterpolateDiscrete;
    valueBufferType = "Array";
    valueTypeName = 'string';
  }

  ///	The value of this method here is 'null', as it does not make sense
	/// for discrete properties.
  @override
  Interpolant? interpolantFactoryMethodLinear(result){return null;}

  /// The value of this method here is 'null', as it does not make sense
	/// for discrete properties.
  @override
  Interpolant? interpolantFactoryMethodSmooth(result) {return null;}

  @override
  StringKeyframeTrack clone(){
    return StringKeyframeTrack(name, times, values);
  }
}
