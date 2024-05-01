import 'package:three_js_math/three_js_math.dart';
import '../animations/keyframe_track.dart';
import '../interpolants/index.dart';

/// A Track of Boolean keyframe values.
class BooleanKeyframeTrack extends KeyframeTrack {
  /// [name] - identifier for the KeyframeTrack.
  ///
  /// [times] - array of keyframe times.
  /// 
  /// [values] - values for the keyframes at the times specified.
  /// 
  BooleanKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    valueBufferType = "Array";
    defaultInterpolation = InterpolateDiscrete;
    valueTypeName = 'bool';
  }

  ///	The value of this method here is 'null', as it does not make sense
	/// for discrete properties.
  @override
  Interpolant? interpolantFactoryMethodLinear(result){return null;}
  
  /// The value of this method here is 'null', as it does not make sense
	/// for discrete properties.
  @override
  Interpolant? interpolantFactoryMethodSmooth(result){return null;}
  
  @override
  BooleanKeyframeTrack clone(){
    return BooleanKeyframeTrack(name, times, values);
  }
}
