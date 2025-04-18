import 'package:three_js_core/textures/index.dart';
import './texture.dart';
import 'dart:js_interop';

@JS('CubeTexture')
class CubeTexture extends Texture {
  bool isCubeTexture = true;

  external CubeTexture([
    images,
    int? mapping, 
    int? wrapS, 
    int? wrapT, 
    int? magFilter, 
    int? minFilter, 
    int? format, 
    int? type,
    int? anisotropy, 
    int? encoding
  ]);

  external get images;
  external set images(value);
}
