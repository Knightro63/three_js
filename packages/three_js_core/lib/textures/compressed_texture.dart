import 'package:three_js_core/others/index.dart';

import 'image_element.dart';
import './texture.dart';

class CompressedTexture extends Texture {
   
  CompressedTexture(
    mipmaps, 
    int width, 
    int height,
    [
      int? format, 
      int? type, 
      int? mapping, 
      int? wrapS, 
      int? wrapT,
      int? magFilter, 
      int? minFilter, 
      int? anisotropy, 
      int? encoding
    ]
  ):super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, encoding) {
    // this.image = ImageDataInfo(null, width, height, null);
    isCompressedTexture = true;
    console.info(" CompressedTexture todo ============ ");

    image = ImageElement(width: width, height: height);

    this.mipmaps = mipmaps;

    // no flipping for cube textures
    // (also flipping doesn't work for compressed textures )

    flipY = false;

    // can't generate mipmaps for compressed textures
    // mips must be embedded in DDS files

    generateMipmaps = false;
  }
}
