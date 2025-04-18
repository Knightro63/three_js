import './texture.dart';
import 'dart:js_interop';

@JS('CanvasTexture')
class CanvasTexture extends Texture {
  bool isCanvasTexture = true;

  external CanvasTexture([
    dynamic canvas,
    int? mapping, 
    int? wrapS, 
    int? wrapT,
    int? magFilter, 
    int? minFilter,
    int? format,
    int? type, 
    int? anisotropy,
  ]);
}
