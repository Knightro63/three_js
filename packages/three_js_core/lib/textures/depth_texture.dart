import 'package:three_js_math/three_js_math.dart';
import 'image_element.dart';
import './texture.dart';

/// This class can be used to automatically save the depth information of a rendering into a texture.
class DepthTexture extends Texture {

  /// [width] - width of the texture.
  /// 
  /// [height] - height of the texture.
  /// 
  /// [type] - Default is [UnsignedIntType]
  /// when using [DepthFormat] and [UnsignedInt248Type] 
  /// when using [DepthStencilFormat].
  /// See [type constants] for other choices.
  /// 
  /// [mapping] - See [mapping mode constants] for
  /// details.
  /// 
  /// [wrapS] - The default is [ClampToEdgeWrapping]. 
  /// See [wrap mode constants] for
  /// other choices.
  /// 
  /// [wrapT] - The default is [ClampToEdgeWrapping]. 
  /// See [wrap mode constants] for
  /// other choices.
  /// 
  /// [magFilter] - How the texture is sampled when a texel
  /// covers more than one pixel. The default is [NearestFilter]. 
  /// See [magnification filter constants]
  /// for other choices.
  /// 
  /// [minFilter] - How the texture is sampled when a texel
  /// covers less than one pixel. The default is [NearestFilter]. 
  /// See [minification filter constants]
  /// for other choices.
  /// 
  /// [anisotropy] - The number of samples taken along the axis
  /// through the pixel that has the highest density of texels. By default, this
  /// value is `1`. A higher value gives a less blurry result than a basic mipmap,
  /// at the cost of more texture samples being used. Use
  /// [page:WebGLrenderer.getMaxAnisotropy renderer.getMaxAnisotropy]() to find
  /// the maximum valid anisotropy value for the GPU; this value is usually a
  /// power of 2.
  /// 
  /// [format] - must be either [DepthFormat]
  /// (default) or [DepthStencilFormat]. See [format constants] for details.
  /// 
  DepthTexture(
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
  ):super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy) {
    isDepthTexture = true;
    format = format ?? DepthFormat;

    if (format != DepthFormat && format != DepthStencilFormat) {
      throw ('DepthTexture format must be either DepthFormat or DepthStencilFormat');
    }

    if (type == null && format == DepthFormat) type = UnsignedShortType;
    if (type == null && format == DepthStencilFormat) type = UnsignedInt248Type;

    image = ImageElement(width: width, height: height);

    this.magFilter = magFilter ?? NearestFilter;
    this.minFilter = minFilter ?? NearestFilter;

    flipY = false;
    generateMipmaps = false;
  }

  @override
  DepthTexture clone() {
    return super.clone() as DepthTexture; 
  }
 
}
