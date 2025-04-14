import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';

class TypeByteLength{
  int components;
  int byteLength;

  TypeByteLength({
    required this.byteLength,
    required this.components
  });
}

class TextureUtils {
  /**
   * Determines how many bytes must be used to represent the texture.
   *
   * @param {number} width - The width of the texture.
   * @param {number} height - The height of the texture.
   * @param {number} format - The texture's format.
   * @param {number} type - The texture's type.
   * @return {number} The byte length.
   */
  static num getByteLength(num width,num height, int format, int type ) {

    final TypeByteLength typeByteLength = getTextureTypeByteLength( type );

    switch ( format ) {

      // https://registry.khronos.org/OpenGL-Refpages/es3.0/html/glTexImage2D.xhtml
      case AlphaFormat:
        return width * height;
      case LuminanceFormat:
        return width * height;
      case LuminanceAlphaFormat:
        return width * height * 2;
      case RedFormat:
        return ( ( width * height ) / typeByteLength.components ) * typeByteLength.byteLength;
      case RedIntegerFormat:
        return ( ( width * height ) / typeByteLength.components ) * typeByteLength.byteLength;
      case RGFormat:
        return ( ( width * height * 2 ) / typeByteLength.components ) * typeByteLength.byteLength;
      case RGIntegerFormat:
        return ( ( width * height * 2 ) / typeByteLength.components ) * typeByteLength.byteLength;
      case RGBFormat:
        return ( ( width * height * 3 ) / typeByteLength.components ) * typeByteLength.byteLength;
      case RGBAFormat:
        return ( ( width * height * 4 ) / typeByteLength.components ) * typeByteLength.byteLength;
      case RGBAIntegerFormat:
        return ( ( width * height * 4 ) / typeByteLength.components ) * typeByteLength.byteLength;

      // https://registry.khronos.org/webgl/extensions/WEBGL_compressed_texture_s3tc_srgb/
      case RGB_S3TC_DXT1_Format:
      case RGBA_S3TC_DXT1_Format:
        return ( ( width + 3 ) / 4 ).floor() * ( ( height + 3 ) / 4 ).floor() * 8;
      case RGBA_S3TC_DXT3_Format:
      case RGBA_S3TC_DXT5_Format:
        return ( ( width + 3 ) / 4 ).floor() * ( ( height + 3 ) / 4 ).floor() * 16;

      // https://registry.khronos.org/webgl/extensions/WEBGL_compressed_texture_pvrtc/
      case RGB_PVRTC_2BPPV1_Format:
      case RGBA_PVRTC_2BPPV1_Format:
        return ( math.max( width, 16 ) * math.max( height, 8 ) ) / 4;
      case RGB_PVRTC_4BPPV1_Format:
      case RGBA_PVRTC_4BPPV1_Format:
        return ( math.max( width, 8 ) * math.max( height, 8 ) ) / 2;

      // https://registry.khronos.org/webgl/extensions/WEBGL_compressed_texture_etc/
      case RGB_ETC1_Format:
      case RGB_ETC2_Format:
        return ( ( width + 3 ) / 4 ).floor() * ( ( height + 3 ) / 4 ).floor() * 8;
      case RGBA_ETC2_EAC_Format:
        return ( ( width + 3 ) / 4 ).floor() * ( ( height + 3 ) / 4 ).floor() * 16;

      // https://registry.khronos.org/webgl/extensions/WEBGL_compressed_texture_astc/
      case RGBA_ASTC_4x4_Format:
        return ( ( width + 3 ) / 4 ).floor() * ( ( height + 3 ) / 4 ).floor() * 16;
      case RGBA_ASTC_5x4_Format:
        return ( ( width + 4 ) / 5 ).floor() * ( ( height + 3 ) / 4 ).floor() * 16;
      case RGBA_ASTC_5x5_Format:
        return ( ( width + 4 ) / 5 ).floor() * ( ( height + 4 ) / 5 ).floor() * 16;
      case RGBA_ASTC_6x5_Format:
        return ( ( width + 5 ) / 6 ).floor() * ( ( height + 4 ) / 5 ).floor() * 16;
      case RGBA_ASTC_6x6_Format:
        return ( ( width + 5 ) / 6 ).floor() * ( ( height + 5 ) / 6 ).floor() * 16;
      case RGBA_ASTC_8x5_Format:
        return ( ( width + 7 ) / 8 ).floor() * ( ( height + 4 ) / 5 ).floor() * 16;
      case RGBA_ASTC_8x6_Format:
        return ( ( width + 7 ) / 8 ).floor() * ( ( height + 5 ) / 6 ).floor() * 16;
      case RGBA_ASTC_8x8_Format:
        return ( ( width + 7 ) / 8 ).floor() * ( ( height + 7 ) / 8 ).floor() * 16;
      case RGBA_ASTC_10x5_Format:
        return ( ( width + 9 ) / 10 ).floor() * ( ( height + 4 ) / 5 ).floor() * 16;
      case RGBA_ASTC_10x6_Format:
        return ( ( width + 9 ) / 10 ).floor() * ( ( height + 5 ) / 6 ).floor() * 16;
      case RGBA_ASTC_10x8_Format:
        return ( ( width + 9 ) / 10 ).floor() * ( ( height + 7 ) / 8 ).floor() * 16;
      case RGBA_ASTC_10x10_Format:
        return ( ( width + 9 ) / 10 ).floor() * ( ( height + 9 ) / 10 ).floor() * 16;
      case RGBA_ASTC_12x10_Format:
        return ( ( width + 11 ) / 12 ).floor() * ( ( height + 9 ) / 10 ).floor() * 16;
      case RGBA_ASTC_12x12_Format:
        return ( ( width + 11 ) / 12 ).floor() * ( ( height + 11 ) / 12 ).floor() * 16;

      // https://registry.khronos.org/webgl/extensions/EXT_texture_compression_bptc/
      case RGBA_BPTC_Format:
      case RGB_BPTC_SIGNED_Format:
      case RGB_BPTC_UNSIGNED_Format:
        return ( width / 4 ).ceil() * ( height / 4 ).ceil() * 16;

      // https://registry.khronos.org/webgl/extensions/EXT_texture_compression_rgtc/
      case RED_RGTC1_Format:
      case SIGNED_RED_RGTC1_Format:
        return ( width / 4 ).ceil() *  (height / 4 ).ceil() * 8;
      case RED_GREEN_RGTC2_Format:
      case SIGNED_RED_GREEN_RGTC2_Format:
        return ( width / 4 ).ceil() * ( height / 4 ).ceil() * 16;

    }

    throw('Unable to determine texture byte length for ${format} format.',);
  }

  static TypeByteLength getTextureTypeByteLength(int type ) {
    switch ( type ) {
      case UnsignedByteType:
      case ByteType:
        return TypeByteLength(byteLength: 1, components: 1 );
      case UnsignedShortType:
      case ShortType:
      case HalfFloatType:
        return TypeByteLength(byteLength: 2, components: 1);
      case UnsignedShort4444Type:
      case UnsignedShort5551Type:
        return TypeByteLength(byteLength: 2, components: 4);
      case UnsignedIntType:
      case IntType:
      case FloatType:
        return TypeByteLength(byteLength: 4, components: 1);
      case UnsignedInt5999Type:
        return TypeByteLength(byteLength: 4, components: 3);
    }

    throw( 'Unknown texture type ${type}.' );
  }
}