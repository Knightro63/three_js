import 'package:three_js_math/three_js_math.dart';
import './texture.dart';

class CubeTexture extends Texture {
  bool isCubeTexture = true;

  CubeTexture([
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
  ]):super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type,anisotropy, encoding) {
    images = images ?? [];
    mapping = mapping ?? CubeReflectionMapping;

    flipY = false;
  }

  get images {
    return image;
  }

  set images(value) {
    image = value;
  }
}
