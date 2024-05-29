import 'package:three_js_math/three_js_math.dart';
import 'image_element.dart';
import './texture.dart';

/// Creates an array of textures directly from raw data, width and height and depth.
class DataArrayTexture extends Texture {
  bool isDataTexture2DArray = true;

  /// The data argument must be an
  /// [ArrayBufferView](https://developer.mozilla.org/en-US/docs/Web/API/ArrayBufferView). 
  /// The properties inherited from [page:Texture] are the
  /// default, except magFilter and minFilter default to NearestFilter.
  /// The properties flipY and generateMipmaps are initially set to false.
  /// 
  /// The interpretation of the data depends on type and format: If the type is
  /// UnsignedByteType, a Uint8List will be useful for addressing the
  /// texel data. If the format is RGBAFormat, data needs four values for
  /// one texel; Red, Green, Blue and Alpha (typically the opacity).
  /// 
  /// For the packed types, UnsignedShort4444Type and
  /// UnsignedShort5551Type all color components of one texel can be
  /// addressed as bitfields within an integer element of a Uint16Array.
  /// 
  /// In order to use the types FloatType and HalfFloatType, the
  /// WebGL implementation must support the respective extensions
  /// OES_texture_float and OES_texture_half_float. In order to use
  /// LinearFilter for component-wise, bilinear interpolation of the
  /// texels based on these types, the WebGL extensions OES_texture_float_linear
  /// or OES_texture_half_float_linear must also be present.
  /// 
  /// This creates a [name] where each texture has a different color.
  /// 
  /// ```
  /// // create a buffer with color data
  /// const width = 512;
  /// const height = 512;
  /// const depth = 100;
  /// 
  /// final size = width * height;
  /// final data = Uint8List( 4 * size * depth );
  /// 
  /// for (int i = 0; i < depth; i ++){
  ///   final color = Color( math.Random().nextDouble(), math.Random().nextDouble(), math.random().nextDouble());
  ///   final r = ( color.r * 255 ).floor();
  ///   final g = ( color.g * 255 ).floor();
  ///   final b = ( color.b * 255 ).floor();
  /// 
  ///   for (int j = 0; j < size; j ++ ) {
  ///     final stride = ( i * size + j ) * 4;
  ///     data[ stride ] = r;
  ///     data[ stride + 1 ] = g;
  ///     data[ stride + 2 ] = b;
  ///     data[ stride + 3 ] = 255;
  ///   }
  /// }

  /// // used the buffer to create a [name]
  /// final texture = DataArrayTexture( data, width, height, depth );
  /// texture.needsUpdate = true;
  /// ```
  DataArrayTexture([data, int width = 1, int height = 1, int depth = 1]):super() {
    image = ImageElement(data: data, width: width, height: height, depth: depth);

    magFilter = NearestFilter;
    minFilter = NearestFilter;

    wrapR = ClampToEdgeWrapping;

    generateMipmaps = false;
    flipY = false;
    unpackAlignment = 1;
  }
}
