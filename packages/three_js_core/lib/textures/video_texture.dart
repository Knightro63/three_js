import 'package:three_js_math/three_js_math.dart';
import './texture.dart';

class VideoTexture extends Texture {

  /// [video] - The video element to use as the texture.
  ///
  /// [mapping] - How the image is applied to the object. An
  /// object type of [page:Textures UVMapping]. 
  /// See [page:Textures mapping constants] for other choices.
  /// 
  /// [wrapS] - The default is [page:Textures ClampToEdgeWrapping]. 
  /// See [page:Textures wrap mode constants] for
  /// other choices.
  /// 
  /// [wrapT] - The default is [page:Textures ClampToEdgeWrapping]. 
  /// See [page:Textures wrap mode constants] for
  /// other choices.
  /// 
  /// [magFilter] - How the texture is sampled when a texel
  /// covers more than one pixel. The default is [page:Textures LinearFilter]. 
  /// See [page:Textures magnification filter constants]
  /// for other choices.
  /// 
  /// [minFilter] - How the texture is sampled when a texel
  /// covers less than one pixel. The default is [page:Textures LinearFilter]. 
  /// See [page:Textures minification filter constants] for
  /// other choices.
  /// 
  /// [format] - The default is [page:Textures RGBAFormat].
  /// See [page:Textures format constants] for other choices.
  /// 
  /// [type] - Default is [page:Textures UnsignedByteType].
  /// See [page:Textures type constants] for other choices.
  /// 
  /// [anisotropy] - The number of samples taken along the axis
  /// through the pixel that has the highest density of texels. By default, this
  /// value is `1`. A higher value gives a less blurry result than a basic mipmap,
  /// at the cost of more texture samples being used. Use
  /// [renderer.getMaxAnisotropy]() to find
  /// the maximum valid anisotropy value for the GPU; this value is usually a
  /// power of 2.
  /// 
  /// 
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

  /// This is called automatically and sets [needsUpdate] 
  /// to `true` every time a new frame is available.
  void update() {
    throw('This is not implimented yet.');
    // final video = image;
    // var hasVideoFrameCallback = 'requestVideoFrameCallback' in video;
    // if ( hasVideoFrameCallback == false && video.readyState >= video.HAVE_CURRENT_DATA ) {
    // 	needsUpdate = true;
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
