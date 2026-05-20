import 'package:three_js_core/materials/line_basic_material.dart';
import 'node_material.dart';

final _defaultValues = /*@__PURE__*/ new LineBasicMaterial();

/**
 * Node material version of {@link LineBasicMaterial}.
 *
 * @augments NodeMaterial
 */
class LineBasicNodeMaterial extends NodeMaterial {
	String get type => 'LineBasicNodeMaterial';
	
	LineBasicNodeMaterial( parameters ):super() {
		this.setDefaultValues( _defaultValues );
		this.setValues( parameters );
	}
}
