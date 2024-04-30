import 'package:three_js_math/three_js_math.dart';
import './texture.dart';

class VideoTexture extends Texture {
  VideoTexture([
    video, 
    int? mapping, 
    int? wrapS, 
    int? wrapT, 
    int? magFilter, 
    int? minFilter, 
    int? format, 
    int? type,
    int? anisotropy
  ]):super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy) {
    isVideoTexture = true;
    this.minFilter = minFilter ?? LinearFilter;
    this.magFilter = magFilter ?? LinearFilter;

    generateMipmaps = false;
  }

  @override
  VideoTexture clone() {
    return VideoTexture(image)..copy(this);
  }

  void update() {
    // var video = this.image;
    // var hasVideoFrameCallback = 'requestVideoFrameCallback' in video;
    // if ( hasVideoFrameCallback == false && video.readyState >= video.HAVE_CURRENT_DATA ) {
    // 	this.needsUpdate = true;
    // }
  }

  // updateVideo() {

  // 	this.needsUpdate = true;
  // 	video.requestVideoFrameCallback( updateVideo );

  // }

  // if ( 'requestVideoFrameCallback' in video ) {

  // 	video.requestVideoFrameCallback( updateVideo );

  // }

}
