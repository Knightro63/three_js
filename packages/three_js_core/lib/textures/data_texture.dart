import 'image_element.dart';
import './texture.dart';

/// Creates a texture directly from raw data, width and height.
class DataTexture extends Texture {

  /// The data argument must be an
  /// [ArrayBufferView](https://developer.mozilla.org/en-US/docs/Web/API/ArrayBufferView). 
  /// Further parameters correspond to the properties
  /// inherited from [Texture], where both magFilter and minFilter default
  /// to NearestFilter.
  /// 
  /// The interpretation of the data depends on type and format: If the type is
  /// UnsignedByteType, a Uint8Array will be useful for addressing the
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
  /// ```
  /// const width = 512;
  /// const height = 512;
  /// 
  /// final size = width * height;
  /// final data = Uint8Array( 4 * size );
  /// final color = Color.fromHex32( 0xffffff );
  /// 
  /// final r = Math.floor( color.r * 255 );
  /// final g = Math.floor( color.g * 255 );
  /// final b = Math.floor( color.b * 255 );
  /// 
  /// for (int i = 0; i < size; i ++ ) {
  ///   final stride = i * 4;
  ///   data[ stride ] = r;
  ///   data[ stride + 1 ] = g;
  ///   data[ stride + 2 ] = b;
  ///   data[ stride + 3 ] = 255;
  /// }
  /// 
  /// // used the buffer to create a [name]
  /// final texture = DataTexture( data, width, height );
  /// texture.needsUpdate = true;
  /// ```
  DataTexture([
    data,
    int? width,
    int? height,
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
    image = ImageElement(data: data, width: width ?? 1, height: height ?? 1);

    generateMipmaps = false;
    flipY = false;
    unpackAlignment = 1;
  }

  factory DataTexture.fromMap(Map<String,dynamic> map){
    return DataTexture(
      map['data'],
      map['width'],
      map['height'],
      map['format'],
      map['type'],
      map['mapping'],
      map['wrapS'],
      map['wrapT'],
      map['magFilter'],
      map['minFilter'],
      map['anisotropy'],
      map['encoding']
    );
  }
}
