import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light.dart';

class LightProbe extends Light {
  LightProbe.create([SphericalHarmonics3? sh, double? intensity]) : super(null, intensity){
    type = 'LightProbe';
  }
  
  factory LightProbe([SphericalHarmonics3? sh, double? intensity]){
    sh ??= SphericalHarmonics3();
    return LightProbe.create(sh, intensity);
  }
  factory LightProbe.fromJson(Map<String,dynamic> json, [Map<String,dynamic>? rootJson]){
    SphericalHarmonics3 sh3 = SphericalHarmonics3();
    sh3.fromArray(json['sh']);
    return LightProbe.create(sh3, json['intensity']);
  }

  @override
  LightProbe copy(Object3D source, [bool? recursive]) {
    super.copy(source);
    LightProbe source1 = source as LightProbe;
    sh!.copy(source1.sh!);
    return this;
  }

  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    Map<String, dynamic> data = super.toJson(meta: meta);
    data["object"]['sh'] = sh!.toArray([]);
    return data;
  }
}
