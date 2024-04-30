import 'package:three_js_math/three_js_math.dart';
import './texture.dart';

class OpenGLTexture extends Texture {
  dynamic openGLTexture;

  OpenGLTexture(
    this.openGLTexture,
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
  ):super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type,anisotropy) {
    isOpenGLTexture = true;

    this.format = format ?? RGBAFormat;
    this.minFilter = minFilter ?? LinearFilter;
    this.magFilter = magFilter ?? LinearFilter;

    generateMipmaps = false;
    needsUpdate = true;
  }

  @override
  OpenGLTexture clone() {
    return OpenGLTexture(image)..copy(this);
  }

  void update() {
    needsUpdate = true;
  }
}
