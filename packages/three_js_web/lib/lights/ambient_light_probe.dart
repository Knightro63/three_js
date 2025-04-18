@JS('THREE')
import '../core/index.dart';
import '../math/index.dart';
import 'light_probe.dart';
import 'dart:js_interop';

@JS('AmbientLightProbe')
class AmbientLightProbe extends LightProbe{
  external AmbientLightProbe(Color color, [double intensity = 1.0]);
  final bool isAmbientLightProbe =  true;
  Map<String, dynamic> toJson({Object3dMeta? meta}){
    return toJSON(meta?.toJson());
  }
  external Map<String, dynamic> toJSON(Map? meta);
}
