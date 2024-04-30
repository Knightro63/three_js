import 'package:three_js_math/three_js_math.dart';
import '../animations/keyframe_track.dart';
import '../interpolants/interpolant.dart';

/// A Track that interpolates Strings
class StringKeyframeTrack extends KeyframeTrack {
  StringKeyframeTrack(super.name,super.times,super.values, [super.interpolation]){
    defaultInterpolation = InterpolateDiscrete;
    valueBufferType = "Array";
    valueTypeName = 'string';
  }

  @override
  Interpolant? interpolantFactoryMethodLinear(result){return null;}

  @override
  Interpolant? interpolantFactoryMethodSmooth(result) {return null;}

  @override
  StringKeyframeTrack clone(){
    return StringKeyframeTrack(name, times, values);
  }
}
