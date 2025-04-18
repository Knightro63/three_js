import 'compressed_texture.dart';
import 'dart:js_interop';

@JS('CompressedArrayTexture')
class CompressedArrayTexture extends CompressedTexture {
	external CompressedArrayTexture([
    mipmaps, 
    int width = 1, 
    int height = 1,
    int depth = 1,
    int? format, 
    int? type, 
  ]);
}