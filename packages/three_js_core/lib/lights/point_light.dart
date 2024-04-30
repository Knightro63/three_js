import '../core/index.dart';
import 'dart:math' as math;
import 'light.dart';
import 'point_light_shadow.dart';

class PointLight extends Light {
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

  @override
  PointLight copy(Object3D source, [bool? recursive]) {
    super.copy.call(source);
    PointLight source1 = source as PointLight;

    distance = source1.distance;
    decay = source1.decay;
    shadow = source1.shadow!.clone();

    return this;
  }

  @override
  void dispose() {
    shadow?.dispose();
  }
}
