import 'package:three_js_core/materials/mesh_toon_material.dart';
import '../nodes/functions/toon_lighting_model.dart';
import 'node_materials.dart';

final _defaultValues = /*@__PURE__*/ new MeshToonMaterial();

/// Node material version of {@link MeshToonMaterial}.
class MeshToonNodeMaterial extends NodeMaterial {
	String get type => 'MeshToonNodeMaterial';
	bool lights = true;

	MeshToonNodeMaterial( parameters ):super() {
		this.setDefaultValues( _defaultValues );
		this.setValues( parameters );
	}

	/// Setups the lighting model.
	ToonLightingModel setupLightingModel( /*builder*/ ) {
		return new ToonLightingModel();
	}
}
