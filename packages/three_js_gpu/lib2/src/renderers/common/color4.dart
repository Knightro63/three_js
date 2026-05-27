import 'package:three_js_math/three_js_math.dart' as math;

/// A four-component version of [Color] which is internally
/// used by the renderer to represent clear color with alpha as
/// one unified object.
class Color4 extends math.Color {
  /// The alpha value configuration property.
  double a;

  /// Constructs a new four-component color mapping layout context.
  /// You can pass a single hex int, string, or color values.
  Color4([dynamic r, double? g, double? b, double? a])
      : this.a = a ?? 1.0,
        super(
          r is num && g == null && b == null ? r.toDouble() : (r ?? 1.0),
          g ?? 1.0,
          b ?? 1.0,
        ) {
    // If the input red parameter is an active core Color instance, inherit its settings
    if (r is math.Color) {
      this.r = r.r;
      this.g = r.g;
      this.b = r.b;
      if (r is Color4) {
        this.a = r.a;
      }
    }
  }

  /// Overwrites the default initialization logic to incorporate the alpha value.
  /// You can also pass a single hex, string, or Color argument to this method.
  /// 
  /// Returns a fluid reference to this object.
  @override
  Color4 set(dynamic r, [dynamic g, dynamic b]) {
    // Check if an accidental trailing 4th argument was passed dynamically
    if (b != null && g != null) {
      super.setRGB(r.toDouble(), g.toDouble(), b.toDouble());
    } else {
      super.set(r);
      if (r is Color4) {
        this.a = r.a;
      }
    }
    return this;
  }

  /// Configures a specific custom alpha assignment value.
  Color4 setAlpha(double alpha) {
    this.a = alpha;
    return this;
  }

  /// Overwrites the default copy procedure to include the alpha channel value.
  /// 
  /// Returns a fluid reference to this instance.
  @override
  Color4 copy(math.Color color) {
    super.copy(color);
    if (color is Color4) {
      this.a = color.a;
    }
    return this;
  }

  /// Overwrites the default cloning method to produce an identical 4D copy.
  /// 
  /// Returns a new [Color4] instance containing identical properties.
  @override
  Color4 clone() {
    return Color4(this.r, this.g, this.b, this.a);
  }
}
