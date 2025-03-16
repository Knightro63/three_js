import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light_probe.dart';
import 'dart:math' as math;

class HemisphereLightProbe extends LightProbe {
  HemisphereLightProbe(Color skyColor, Color groundColor, [double intensity = 1.0]):super.create(null, intensity) {
    final color1 = Color(skyColor.red, skyColor.green, skyColor.blue);
    final color2 = Color(groundColor.red, groundColor.green, groundColor.blue);

    final sky = Vector3(color1.red, color1.green, color1.blue);
    final ground = Vector3(color2.red, color2.green, color2.blue);

    // without extra factor of PI in the shader, should = 1 / math.sqrt( math.pi );
    final c0 = math.sqrt(math.pi);
    final c1 = c0 * math.sqrt(0.75);

    sh!.coefficients[0]..setFrom(sky)..add(ground)..scale(c0);
    sh!.coefficients[1]..setFrom(sky)..sub(ground)..scale(c1);

    isHemisphereLightProbe = false;
  }

  @override
  Map<String,dynamic> toJson({Object3dMeta? meta}) {
    final data = super.toJson(meta: meta);
    return data;
  }
}
