import '../animations/keyframe_track.dart';

/// A Track of keyframe values that represent color.
class ColorKeyframeTrack extends KeyframeTrack {
  ColorKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    valueTypeName = 'color';
  }

  @override
  ColorKeyframeTrack clone(){
    return ColorKeyframeTrack(name, times, values);
  }
}
