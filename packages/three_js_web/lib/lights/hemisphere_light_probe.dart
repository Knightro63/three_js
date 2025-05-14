@JS('THREE')
import '../core/index.dart';
import '../math/index.dart';
import 'light_probe.dart';
import 'dart:js_interop';

@JS('PerspectiveCamera')
class HemisphereLightProbe extends LightProbe {
  external HemisphereLightProbe(Color skyColor, Color groundColor, [double intensity = 1.0]);

  @override
  Map<String,dynamic> toJson({Object3dMeta? meta}) {
    return toJSON(meta?.toJson());
  }

  external Map<String, dynamic> toJSON(Map? meta);
}
