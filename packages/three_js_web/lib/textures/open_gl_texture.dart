import './texture.dart';
import 'dart:js_interop';

@JS('OpenGLTexture')
class OpenGLTexture extends Texture {
  external OpenGLTexture(
    dynamic openGLTexture,
    [ 
      int? mapping, 
      int? wrapS, 
      int? wrapT, 
      int? magFilter, 
      int? minFilter,
      int? format, 
      int? type, 
      int? anisotropy
    ]
  );

  @override
  external OpenGLTexture clone();
  external void update();
}
