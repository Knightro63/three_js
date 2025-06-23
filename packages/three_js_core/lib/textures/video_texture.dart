import 'package:flutter/widgets.dart';
export 'video_texture2.dart';
export 'video_texture_platform.dart'
  if (dart.library.js_interop) 'video_texture_web.dart';

class VideoTextureOptions{
  BuildContext? context;
  double? width;
  double? height;
  String asset;
  bool loop;

  VideoTextureOptions({
    this.context,
    this.width,
    this.height,
    required this.asset,
    this.loop = true
  });
}