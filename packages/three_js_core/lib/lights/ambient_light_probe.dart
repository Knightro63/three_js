import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light_probe.dart';
import 'dart:math' as math;

class AmbientLightProbe extends LightProbe{
  AmbientLightProbe(Color color, [double? intensity]):super.create(null,intensity){
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
