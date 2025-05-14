import 'package:three_js_core/textures/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;
import 'package:web/web.dart' as html;

class VideoTexture extends Texture {
  html.HTMLVideoElement? get video => image.data;
  bool _didDispose = false;

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

  factory VideoTexture.fromOptions(
    VideoTextureOptions options,[
    int? mapping, 
    int? wrapS, 
    int? wrapT, 
    int? magFilter, 
    int? minFilter, 
    int? format, 
    int? type,
    int? anisotropy
  ]){
    final videoElement = html.HTMLVideoElement()
    ..id = 'video-id${math.Random().nextInt(100)}'
    ..src = options.asset
    ..loop = options.loop
    ..crossOrigin = "anonymous";

    final image = ImageElement(
      url: options.asset,
      src: options.asset,
      data: videoElement
    );

    return VideoTexture(
      image,
      mapping, 
      wrapS, 
      wrapT, 
      magFilter, 
      minFilter, 
      format, 
      type,
      anisotropy
    );
  }

  @override
  VideoTexture clone() {
    return VideoTexture(image)..copy(this);
  }

  /// This is called automatically and sets [needsUpdate] 
  /// to `true` every time a new frame is available.
  void update() {
    //final video = image.data;
    final hasVideoFrameCallback = video is html.HTMLVideoElement;//'requestVideoFrameCallback' in video.requestVideoFrameCallback(callback);
    if (hasVideoFrameCallback && (video?.readyState ?? 0) >= 4 ) {
      needsUpdate = true;
    }
  }

  html.VideoFrameRequestCallback updateVideo() => _updateVideo();
  _updateVideo(){
    needsUpdate = true;
    video?.requestVideoFrameCallback( updateVideo() );
  }

  void play(){
    video?.play();
  }
  
  void pause(){
    video?.pause();
  }

  @override
  void dispose(){
    if(_didDispose) return;
    video?.pause();
    video?.removeAttribute('src'); // empty source
    //video.load();
    image = null;
    _didDispose = true;
  }
}
