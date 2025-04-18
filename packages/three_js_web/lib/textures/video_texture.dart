import './texture.dart';
import 'dart:js_interop';

@JS('VideoTexture')
class VideoTexture extends Texture {
  external VideoTexture([
    video, 
    int? mapping, 
    int? wrapS, 
    int? wrapT, 
    int? magFilter, 
    int? minFilter, 
    int? format, 
    int? type,
    int? anisotropy
  ]);

  @override
  external VideoTexture clone();

  external void update();
  external void updateVideo();
}
