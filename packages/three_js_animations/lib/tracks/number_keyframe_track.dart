import '../animations/keyframe_track.dart';

/// A Track of numeric keyframe values.
class NumberKeyframeTrack extends KeyframeTrack {
  NumberKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    valueTypeName = "number";
  }
  @override
  NumberKeyframeTrack clone(){
    return NumberKeyframeTrack(name, times, values);
  }
}
