import 'package:three_js_core/three_js_core.dart';

class VideoTextureOptions{
  double? width;
  double? height;
  String asset;
  bool loop;

  VideoTextureOptions({
    this.width,
    this.height,
    required this.asset,
    this.loop = true
  });
}

abstract class VideoTexture extends Texture {
    VideoTexture([
    ImageElement? video, 
    int? mapping, 
    int? wrapS, 
    int? wrapT, 
    int? magFilter, 
    int? minFilter, 
    int? format, 
    int? type,
    int? anisotropy
  ]):super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
  
  void dispose();
  void updateVideo();
  void pause();
  void play();
  void update();
}