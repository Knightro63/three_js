import '../core/index.dart';
import 'dart:math' as math;
import 'light.dart';
import 'point_light_shadow.dart';

/// A light that gets emitted from a single point in all directions. A common
/// use case for this is to replicate the light emitted from a bare
/// lightbulb.
/// 
/// This light can cast shadows - see [PointLightShadow] page for
/// details.
/// 
/// ```
/// final light = PointLight( 0xff0000, 1, 100 );
/// light.position.setValues( 50, 50, 50 );
/// scene.add( light );
/// ```
class PointLight extends Light {
  /// [color] - (optional) hexadecimal color of the light. Default
  /// is 0xffffff (white).
  /// 
  /// [intensity] - (optional) numeric value of the light's
  /// strength/intensity. Default is `1`.
  /// 
  /// [distance] - Maximum range of the light. Default is `0` (no
  /// limit).
  /// 
  /// [decay] - The amount the light dims along the distance of the
  /// light. Default is `2`.
  PointLight(super.color, [super.intensity, double? distance, double? decay]){
    // remove default 0  for js 0 is false  but for dart 0 is not.
    // PointLightShadow.updateMatrices  far value
    this.distance = distance;
    this.decay = decay ?? 1; // for physically correct lights, should be 2.

    shadow = PointLightShadow();
    type = "PointLight";
  }

  PointLight.fromJson(Map<String, dynamic> json, Map<String,dynamic> rootJson):super.fromJson(json,rootJson) {
    type = "PointLight";
    distance = json["distance"];
    decay = json["decay"] ?? 1;
    shadow = PointLightShadow.fromJson(json["shadow"],rootJson);
  }

  double get power {
    return intensity * 4 * math.pi;
  }

  set power(double value) {
    intensity = value / (4 * math.pi);
  }

  /// Copies value of all the properties from the [source] to
  /// this PointLight.
  @override
  PointLight copy(Object3D source, [bool? recursive]) {
    super.copy.call(source);
    PointLight source1 = source as PointLight;

    distance = source1.distance;
    decay = source1.decay;
    shadow = source1.shadow!.clone();

    return this;
  }

  /// Frees the GPU-related resources allocated by this instance. Call this
  /// method whenever this instance is no longer used in your app.
  @override
  void dispose() {
    shadow?.dispose();
  }
}
