import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light.dart';

/// A light source positioned directly above the scene, with color fading from
/// the sky color to the ground color.
/// 
/// This light cannot be used to cast shadows.
/// 
/// ```
/// final light = HemisphereLight(0xffffbb, 0x080820, 1 );
/// scene.add(light);
/// ```
class HemisphereLight extends Light {
  /// [skyColor] - (optional) hexadecimal color of the sky. Default
  /// is 0xffffff.
  /// 
  /// [groundColor] - (optional) hexadecimal color of the ground.
  /// Default is 0xffffff.
  /// 
  /// [intensity] - (optional) numeric value of the light's
  /// strength/intensity. Default is `1`.
  HemisphereLight(int? skyColor, int? groundColor, [double intensity = 1.0]):super(skyColor, intensity) {
    type = 'HemisphereLight';

    position.setFrom(Object3D.defaultUp);

    isHemisphereLight = true;
    updateMatrix();

    if (groundColor != null) {
      this.groundColor = Color.fromHex32(groundColor);
    }
  }

  /// Copies the value of [color], [intensity] and
  /// [groundColor] from the [source] light into
  /// this one.
  @override
  HemisphereLight copy(Object3D source, [bool? recursive]) {
    super.copy(source);
    HemisphereLight source1 = source as HemisphereLight;
    groundColor!.setFrom(source1.groundColor!);
    return this;
  }
}
