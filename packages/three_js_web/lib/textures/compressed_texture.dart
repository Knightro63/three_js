import './texture.dart';
import 'dart:js_interop';

@JS('CompressedTexture')
class CompressedTexture extends Texture {
  external CompressedTexture([
    mipmaps, 
    int width = 1, 
    int height = 1,
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
