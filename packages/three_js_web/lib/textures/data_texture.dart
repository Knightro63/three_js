import './texture.dart';
import 'dart:js_interop';

@JS('DepthTexture')
class DataTexture extends Texture {
  DataTexture([
    dynamic data,
    int? width,
    int? height,
    int? format,
    int? type,
    int? mapping,
    int? wrapS,
    int? wrapT,
    int? magFilter,
    int? minFilter,
    int? anisotropy,
    int? encoding
  ]);
}
