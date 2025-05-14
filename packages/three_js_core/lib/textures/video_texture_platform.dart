import 'package:flutter/material.dart' as wid;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import './texture.dart';
import 'package:video_player/video_player.dart';

class VideoTexture extends Texture {
  ImageElement? get video => image;
  VideoPlayerController? _controller;
  wid.BuildContext? _context;
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
    Map? video, 
    int? mapping, 
    int? wrapS, 
    int? wrapT, 
    int? magFilter, 
    int? minFilter, 
    int? format, 
    int? type,
    int? anisotropy
  ]):super(video?['imageElement'], mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy) {
    isVideoTexture = true;
    this.minFilter = minFilter ?? LinearFilter;
    this.magFilter = magFilter ?? LinearFilter;

    generateMipmaps = false;

    _controller = video?['controller'];
    _context = video?['context'];
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
    final _controller = VideoPlayerController.networkUrl(Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'))..initialize().then((_) {});
    final image = ImageElement(url: _controller);

    return VideoTexture(
      {
        'imageElement':image,
        'context': options.context,
        'controller': _controller
      },
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
  void update(){
    //print('here');
    if(video?.complete == true && _context != null && _controller != null && _controller!.value.isInitialized){
      //print('here2');
      video?.complete = false;
      FlutterTexture.generateImageFromWidget(
        _context!,
        wid.Container(
          color: wid.Colors.red,
          width: 1000,
          height: 1000,
          child: VideoPlayer(_controller!)
        ),
        video
      ).then((value){
        video?.complete = true;
        needsUpdate = true;
      });
    }
  }

  void play(){
    _controller?.play();
  }
  
  void pause(){
    _controller?.pause();
  }

  void updateVideo() {
    needsUpdate = true;
  }

  void dispose(){
    if(_didDispose) return;
    _controller?.pause();
    _controller?.dispose();
    image = null;
    _didDispose = true;
  }
}
