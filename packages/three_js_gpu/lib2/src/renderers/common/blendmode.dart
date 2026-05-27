import 'package:three_js_math/others/constants.dart';

/// Represents blending configuration.
/// 
/// This class encapsulates all blending-related properties that control how
/// a material's colors are combined with the colors already in the frame buffer.
class BlendMode {
  /// Defines the blending type.
  int blending;

  /// Defines the blending source factor.
  int blendSrc;

  /// Defines the blending destination factor.
  int blendDst;

  /// Defines the blending equation.
  int blendEquation;

  /// Defines the blending source alpha factor.
  int? blendSrcAlpha;

  /// Defines the blending destination alpha factor.
  int? blendDstAlpha;

  /// Defines the blending equation of the alpha channel.
  int? blendEquationAlpha;

  /// Defines whether to premultiply the alpha (transparency) value.
  bool premultiplyAlpha = false;

  /// Constructs a new blending configuration layout component.
  /// 
  /// [blending] - The blending mode configuration override.
  BlendMode([int? blending])
      : this.blending = blending ?? NormalBlending,
        this.blendSrc = SrcAlphaFactor,
        this.blendDst = OneMinusSrcAlphaFactor,
        this.blendEquation = AddEquation,
        this.blendSrcAlpha = null,
        this.blendDstAlpha = null,
        this.blendEquationAlpha = null,
        this.premultiplyAlpha = false;

  /// Copies the blending properties from the given source to this instance.
  /// 
  /// [source] - The blending configuration to copy from.
  /// Returns a fluid reference to this instance.
  BlendMode copy(BlendMode source) {
    this.blending = source.blending;
    this.blendSrc = source.blendSrc;
    this.blendDst = source.blendDst;
    this.blendEquation = source.blendEquation;
    this.blendSrcAlpha = source.blendSrcAlpha;
    this.blendDstAlpha = source.blendDstAlpha;
    this.blendEquationAlpha = source.blendEquationAlpha;
    this.premultiplyAlpha = source.premultiplyAlpha;
    return this;
  }

  /// Returns a clone of this blending configuration.
  /// 
  /// Returns a new [BlendMode] instance with the same properties.
  BlendMode clone() {
    return BlendMode().copy(this);
  }
}
