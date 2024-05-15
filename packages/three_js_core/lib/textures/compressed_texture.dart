import 'package:three_js_core/others/index.dart';

import 'image_element.dart';
import './texture.dart';

/// Creates an texture 2D array based on data in compressed form, for example
/// from a [DDS](link:https://en.wikipedia.org/wiki/DirectDraw_Surface)
/// file.
///
/// For use with the [CompressedTextureLoader].
class CompressedTexture extends Texture {
   
  /// [mipmaps] -- The mipmaps array should contain objects with
  /// data, width and height. The mipmaps should be of the correct format and
  /// type.
  /// 
  /// [width] - The width of the biggest mipmap.
  /// 
  /// [height] - The height of the biggest mipmap.
  /// 
  /// [format] - The format used in the mipmaps. See
  /// [ST3C Compressed Texture Formats], [PVRTC Compressed Texture Formats] 
  /// and [ETC Compressed Texture Format] for other choices.
  /// 
  /// [type] - Default is [UnsignedByteType].
  /// See [constants] for other choices.
  /// [mapping] - How the image is applied to the object. An
  /// object type of [UVMapping]. See [mapping constants] for other choices.
  /// 
  /// [wrapS] -- The default is [ClampToEdgeWrapping]. 
  /// See [wrap mode constants] for
  /// other choices.
  /// 
  /// [wrapT] - The default is [ClampToEdgeWrapping]. 
  /// See [wrap mode constants] for
  /// other choices.
  /// 
  /// [magFilter] - How the texture is sampled when a texel
  /// covers more than one pixel. The default is [LinearFilter]. 
  /// See [magnification filter constants]
  /// for other choices.
  /// 
  /// [minFilter] - How the texture is sampled when a texel
  /// covers less than one pixel. The default is [LinearMipmapLinearFilter]. 
  /// See [minification filter constants] for other choices.
  /// 
  /// [anisotropy] - The number of samples taken along the axis
  /// through the pixel that has the highest density of texels. By default, this
  /// value is `1`. A higher value gives a less blurry result than a basic mipmap,
  /// at the cost of more texture samples being used. Use
  /// renderer.getMaxAnisotropy() to find the maximum valid anisotropy value for
  /// the GPU; this value is usually a power of 2.
  /// 
  /// [encoding] - The default is [NoColorSpace]. 
  /// See [color space constants] for other
  /// choices.
  /// 
  /// 
  CompressedTexture([
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
  ]):super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, encoding) {
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
