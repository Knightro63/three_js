import '../core/index.dart';
import 'dart:math' as math;

import 'light.dart';
import 'spot_light_shadow.dart';

class SpotLight extends Light {
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

  @override
  void dispose() {
    shadow!.dispose();
  }
}
