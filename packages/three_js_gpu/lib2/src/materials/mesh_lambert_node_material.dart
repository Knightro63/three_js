import 'package:three_js_core/three_js_core.dart';
import 'node_material.dart';

final _defaultValues = /*@__PURE__*/ MeshLambertMaterial();

/**
 * Node material version of {@link MeshLambertMaterial}.
 *
 * @augments NodeMaterial
 */
class MeshLambertNodeMaterial extends NodeMaterial {
	String get type => 'MeshLambertNodeMaterial';

  /**
   * Set to `true` because lambert materials react on lights.
   */
  bool lights = true;

	MeshLambertNodeMaterial( parameters ):super() {
		this.setDefaultValues( _defaultValues );
		this.setValues( parameters );
	}

	/**
	 * Overwritten since this type of material uses {@link BasicEnvironmentNode}
	 * to implement the default environment mapping.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {?} The environment node.
	 */
	BasicEnvironmentNode<vec3>? setupEnvironment(NodeBuilder builder ) {
		final envNode = super.setupEnvironment( builder );
		return envNode ? new BasicEnvironmentNode( envNode ) : null;
	}

	/**
	 * Setups the lighting model.
	 *
	 * @return {PhongLightingModel} The lighting model.
	 */
	PhongLightingModel setupLightingModel( /*builder*/ ) {
		return new PhongLightingModel( false ); // ( specular ) -> force lambert
	}
}
