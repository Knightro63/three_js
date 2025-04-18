import './texture.dart';
import 'dart:js_interop';

@JS('DepthTexture')
class DepthTexture extends Texture {
  external int? compareFunction;

  external DepthTexture(
    int width, 
    int height,
    [
      int? type, 
      int? mapping, 
      int? wrapS, 
      int? wrapT, 
      int? magFilter,
      int? minFilter,
      int? anisotropy, 
      int? format
    ]
  );

  @override
  external DepthTexture copy(Texture source );

  @override
  external DepthTexture clone();
}
