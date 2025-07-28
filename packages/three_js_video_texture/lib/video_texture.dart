import 'package:flutter/widgets.dart';

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