import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light_probe.dart';
import 'dart:math' as math;

class AmbientLightProbe extends LightProbe{

  /// [color] - (optional) Color value of the RGB component of
  /// the color. Default is Color.fromHex32(0xffffff).
  /// 
  /// [intensity] - (optional) Numeric value of the light's
  /// strength/intensity. Default is `1`.
  /// 
  /// Creates a new [name].
  AmbientLightProbe(Color color, [double intensity = 1.0]):super.create(null,intensity){
    final color1 = Color(color.red, color.green, color.blue);
    // without extra factor of PI in the shader, would be 2 / math.sqrt( math.pi );
    sh!.coefficients[ 0 ].setValues( color1.red, color1.green, color1.blue );
    sh!.coefficients[ 0 ].scale( 2 * math.sqrt( math.pi ) );
  }

  final bool isAmbientLightProbe =  true;

  @override
	Map<String,dynamic> toJson({Object3dMeta? meta}){
		final data = super.toJson(meta:meta);
		// data.sh = this.sh.toArray(); // todo
		return data;
	}
}
