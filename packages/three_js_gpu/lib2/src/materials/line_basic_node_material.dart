import 'package:three_js_core/three_js_core.dart';
import 'node_material.dart';

final _defaultValues = /*@__PURE__*/ new LineBasicMaterial();

/**
 * Node material version of {@link LineBasicMaterial}.
 *
 * @augments NodeMaterial
 */
class LineBasicNodeMaterial extends NodeMaterial {
	String get type => 'LineBasicNodeMaterial';
	
	LineBasicNodeMaterial([Map<MaterialProperty,dynamic>? parameters ]):super() {
		this.setDefaultValues( _defaultValues );
		if(parameters != null) this.setValues( parameters );
	}

  LineBasicNodeMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    this.setDefaultValues( _defaultValues );
    this.setValuesFromString(parameters);
  }
}
