import 'package:three_js_math/three_js_math.dart';
import 'image_element.dart';
import './texture.dart';

class DepthTexture extends Texture {
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
      throw ('DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat');
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
