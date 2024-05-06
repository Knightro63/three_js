import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light_shadow.dart';

/// Abstract base class for lights - all other light types inherit the
/// properties and methods described here.
class Light extends Object3D {
  late double intensity;
  Color? color;
  double? distance;
  LightShadow? shadow;
  SphericalHarmonics3? sh;

  double? angle;
  double? decay;

  Object3D? target;
  double? penumbra;

  double? width;
  double? height;

  bool isRectAreaLight = false;
  bool isHemisphereLightProbe = false;
  bool isHemisphereLight = false;

  Color? groundColor;

  /// [color] - (optional) hexadecimal color of the light. Default
  /// is 0xffffff (white).
  /// 
  /// [intensity] - (optional) numeric value of the light's
  /// strength/intensity. Default is `1`.
  /// 
  /// Creates a new [name]. Note that this is not intended to be called directly
  /// (use one of derived classes instead).
  Light(int? color, [double? intensity]) : super() {
    if(color != null){
      this.color = Color.fromHex32(color);
    }
    this.intensity = intensity ?? 1.0;
    type = "Light";
  }

  Light.fromJson(Map<String,dynamic> json, Map<String,dynamic> rootJson):super.fromJson(json, rootJson){
    type = "Light";
    if (json["color"] != null) {
      color = Color.fromHex32(json["color"]);
    }
    intensity = json["intensity"] ?? 1;
  }

  /// Copies the value of [color] and [intensity]
  /// from the [source] light into this one.
  @override
  Light copy(Object3D source, [bool? recursive]) {
    super.copy(source, false);

    Light source1 = source as Light;

    color!.setFrom(source1.color!);
    intensity = source1.intensity;

    return this;
  }

  /// [meta] - object containing metadata such as materials, textures for
  /// objects.
  /// 
  /// Convert the light to three.js
  /// [JSON Object/Scene format](https://github.com/mrdoob/three.js/wiki/JSON-Object-Scene-format-4).
  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    Map<String, dynamic> data = super.toJson(meta: meta);

    data["object"]["color"] = color!.getHex();
    data["object"]["intensity"] = intensity;

    if (groundColor != null) {
      data["object"]["groundColor"] = groundColor!.getHex();
    }

    if (distance != null) {
      data["object"]["distance"] = distance;
    }
    if (angle != null) {
      data["object"]["angle"] = angle;
    }
    if (decay != null) {
      data["object"]["decay"] = decay;
    }
    if (penumbra != null) {
      data["object"]["penumbra"] = penumbra;
    }

    if (shadow != null) {
      data["object"]["shadow"] = shadow!.toJson();
    }

    return data;
  }

  /// Abstract dispose method for classes that extend this class; implemented by
  /// subclasses that have disposable GPU-related resources.
  @override
  void dispose() {
    // Empty here in base class; some subclasses override.
  }

  @override
  dynamic getProperty(String propertyName) {
    if (propertyName == "color") {
      return color;
    } else if (propertyName == "intensity") {
      return intensity;
    } else {
      return super.getProperty(propertyName);
    }
  }

  @override
  Light setProperty(String propertyName, dynamic value) {
    if (propertyName == "intensity") {
      intensity = value;
    } else {
      super.setProperty(propertyName, value);
    }

    return this;
  }
}
