import 'dart:io';

import 'package:media_kit_video/media_kit_video.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:media_kit/media_kit.dart';

class VideoTextureWorker extends VideoTexture {
  ImageElement? get video => image;
  Player? _player;
  VideoController? _controller;
  bool _didDispose = false;
  bool _updating = false;
  bool _isPlaying = false;

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
  VideoTextureWorker([
    ImageElement? video, 
    int? mapping, 
    int? wrapS, 
    int? wrapT, 
    int? magFilter, 
    int? minFilter, 
    int? format, 
    int? type,
    int? anisotropy
  ]):super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy) {
    MediaKit.ensureInitialized();
    isVideoTexture = true;
    this.minFilter = minFilter ?? LinearFilter;
    this.magFilter = magFilter ?? LinearFilter;

    generateMipmaps = false;

    _player = Player();
    _controller = VideoController(_player!,configuration: VideoControllerConfiguration(
      width: image!.height.toInt(),
      height: image.width.toInt()
    ));
    _player!.open(Media(_convert(image.src!))).then((_){
      if((image.url as VideoTextureOptions).loop){
        _player!.setPlaylistMode(PlaylistMode.single);
        _isPlaying = true;
      }
    });
  }

  static String _convert(dynamic url){
    if(url is File){
      return 'file:///${url.path}';
    }
    else if(url is Uri){
      return url.path;
    }
    else if(url is String){
      if(url.contains('http://') || url.contains('https://')){  
        return url;
      }
      else if(url.contains('assets')){
        return 'asset:///$url';
      }
    }

    throw('File type not allowed. Must be a path, asset, or url string.');
  }

  factory VideoTextureWorker.fromOptions(
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
    final image = ImageElement(
      url: options,
      //data: Uint8Array(391680),//((options.width ?? 0)*(options.height ?? 0)*4).toInt()),
      src: options.asset,
      width: options.width?.toInt() ?? 0,
      height: options.height?.toInt() ?? 0
    );

    return VideoTextureWorker(
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
  VideoTextureWorker clone() {
    return VideoTextureWorker(image)..copy(this);
  }

  /// This is called automatically and sets [needsUpdate] 
  /// to `true` every time a new frame is available.
  void update(){
    if(!_updating && _isPlaying){
      _updating = true;
      _player?.screenshot(format: null).then((v){//format: null
        _updating = false;
        if(image != null && v != null){
          if(image?.data == null || image?.data?.length != v.length){
            print('getyweduwb');
            image!.data = Uint8Array.fromList(v);
            image!.width = _player?.state.width;
            image!.height = _player?.state.height;
          }
          else{
            (image!.data as Uint8Array).set(v);
          }
        }
        needsUpdate = true;
      });
    }
  }

  void play(){
    _player?.play().then((_){
      _isPlaying = true;
      _updating = false;
    });
  }
  
  void pause(){
    _controller?.id;
    _player?.pause().then((_){
      _isPlaying = false;
      _updating = false;
    });
  }

  void updateVideo() {
    needsUpdate = true;
  }

  @override
  void dispose(){
    if(_didDispose) return;
    super.dispose();
    _player?.dispose();
    _player = null;
    _controller = null;
    image = null;
    _didDispose = true;
  }
}
