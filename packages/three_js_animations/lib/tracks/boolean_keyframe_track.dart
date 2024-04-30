import 'package:three_js_math/three_js_math.dart';
import '../animations/keyframe_track.dart';
import '../interpolants/index.dart';

/// A Track of Boolean keyframe values.
class BooleanKeyframeTrack extends KeyframeTrack {
  // Note: Actually this track could have a optimized / compressed
  // representation of a single value and a custom interpolant that
  // computes "firstValue ^ isOdd( index )".
  BooleanKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    valueBufferType = "Array";
    defaultInterpolation = InterpolateDiscrete;
    valueTypeName = 'bool';
  }

  @override
  Interpolant? interpolantFactoryMethodLinear(result){return null;}
  @override
  Interpolant? interpolantFactoryMethodSmooth(result){return null;}
  @override
  BooleanKeyframeTrack clone(){
    return BooleanKeyframeTrack(name, times, values);
  }
}
