import '../animations/keyframe_track.dart';

/// A Track of vectored keyframe values.
class VectorKeyframeTrack extends KeyframeTrack {
  VectorKeyframeTrack(super.name, super.times, super.values, [super.interpolation]){
    valueTypeName = 'vector';
  }

  @override
  VectorKeyframeTrack clone(){
    return VectorKeyframeTrack(name, times, values);
  }
}
