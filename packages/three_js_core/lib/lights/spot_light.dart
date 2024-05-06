import '../core/index.dart';
import 'dart:math' as math;

import 'light.dart';
import 'spot_light_shadow.dart';

/// This light gets emitted from a single point in one direction, along a cone
/// that increases in size the further from the light it gets.
/// 
/// This light can cast shadows - see the [SpotLightShadow] page for
/// details.
/// 
/// ```
/// // white spotlight shining from the side, modulated by a texture, casting a shadow
///
/// final spotLight = SpotLight( 0xffffff );
/// spotLight.position.setValues( 100, 1000, 100 );
/// spotLight.map = TextureLoader().fromUri( url );
///
/// spotLight.castShadow = true;
///
/// spotLight.shadow.mapSize.width = 1024;
/// spotLight.shadow.mapSize.height = 1024;
///
/// spotLight.shadow.camera.near = 500;
/// spotLight.shadow.camera.far = 4000;
/// spotLight.shadow.camera.fov = 30;
///
/// scene.add( spotLight );
/// ```
class SpotLight extends Light {

  /// [color] - (optional) hexadecimal color of the light. Default
  /// is 0xffffff (white).
  /// 
  /// [intensity] - (optional) numeric value of the light's
  /// strength/intensity. Default is `1`.
  /// 
  /// [distance] - Maximum range of the light. Default is `0` (no
  /// limit).
  /// 
  /// [angle] - Maximum angle of light dispersion from its
  /// direction whose upper bound is pi/2.
  /// 
  /// [penumbra] - Percent of the spotlight cone that is attenuated
  /// due to penumbra. Takes values between zero and `1`. Default is zero.
  /// 
  /// [decay] - The amount the light dims along the distance of the
  /// light.
  SpotLight([super.color, super.intensity, double? distance, double? angle, double? penumbra, double? decay]){
    type = "SpotLight";
    position.setFrom(Object3D.defaultUp);
    updateMatrix();

    target = Object3D();

    // remove default 0  for js 0 is false  but for dart 0 is not.
    // SpotLightShadow.updateMatrices  far value
    this.distance = distance;
    this.angle = angle ?? math.pi / 3;
    this.penumbra = penumbra ?? 0;
    this.decay = decay ?? 1; // for physically correct lights, should be 2.

    shadow = SpotLightShadow();
  }

  double get power {
    return intensity * math.pi;
  }

  set power(double value) {
    intensity = value / math.pi;
  }

  /// Copies value of all the properties from the [source] to
  /// this SpotLight.
  @override
  SpotLight copy(Object3D source, [bool? recursive]) {
    super.copy(source);

    SpotLight source1 = source as SpotLight;

    distance = source1.distance;
    angle = source1.angle;
    penumbra = source1.penumbra;
    decay = source1.decay;

    target = source1.target!.clone();
    shadow = source1.shadow!.clone();
    
    return this;
  }

  /// Frees the GPU-related resources allocated by this instance. Call this
  /// method whenever this instance is no longer used in your app.
  @override
  void dispose() {
    shadow!.dispose();
  }
}
