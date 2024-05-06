import './texture.dart';

/// Creates a texture from a canvas element.
/// 
/// This is almost the same as the base [Texture] class, except
/// that it sets [needsUpdate] to `true` immediately.
class CanvasTexture extends Texture {
  bool isCanvasTexture = true;

  /// [canvas] -- The HTML canvas element from which to load
  /// the texture.
  /// 
  /// [mapping] -- How the image is applied to the object. An
  /// object type of [UVMapping]. See [constants] for other choices.
  /// 
  /// [wrapS] -- The default is [ClampToEdgeWrapping]. 
  /// See [constants] for
  /// other choices.
  /// 
  /// [wrapT] -- The default is [ClampToEdgeWrapping]. 
  /// See [constants] for
  /// other choices.
  /// 
  /// [magFilter] -- How the texture is sampled when a texel
  /// covers more than one pixel. The default is [LinearFilter]. 
  /// See [constants]
  /// for other choices.
  /// 
  /// [minFilter] -- How the texture is sampled when a texel
  /// covers less than one pixel. The default is [LinearMipmapLinearFilter]. 
  /// See [constants] for other choices.
  /// 
  /// [format] -- The format used in the texture. See
  /// [page:Textures format constants] for other choices.
  /// 
  /// [type] -- Default is [UnsignedByteType].
  /// See [constants] for other choices.
  /// 
  /// [anisotropy] -- The number of samples taken along the axis
  /// through the pixel that has the highest density of texels. By default, this
  /// value is `1`. A higher value gives a less blurry result than a basic mipmap,
  /// at the cost of more texture samples being used. Use
  /// [renderer.getMaxAnisotropy] to find
  /// the maximum valid anisotropy value for the GPU; this value is usually a
  /// power of 2.
  /// 
  /// 
  CanvasTexture([
    super.canvas,
    super.mapping, 
    super.wrapS, 
    super.wrapT, 
    super.magFilter, 
    super.minFilter, 
    super.format,
    super.type, 
    super.anisotropy
  ]){
    needsUpdate = true;
  }
}
