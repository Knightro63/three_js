import 'package:three_js_core/materials/mesh_basic_material.dart';
import 'node_material.dart';

final _defaultValues = /*@__PURE__*/ MeshBasicMaterial();

/**
 * Node material version of {@link MeshBasicMaterial}.
 *
 * @augments NodeMaterial
 */
class MeshBasicNodeMaterial extends NodeMaterial {
	String get type => 'MeshBasicNodeMaterial';
  bool lights = true;
	
	/**
	 * Constructs a new mesh basic node material.
	 *
	 * @param {Object} [parameters] - The configuration parameter.
	 */
	MeshBasicNodeMaterial( parameters ):super() {
		this.setDefaultValues( _defaultValues );
		this.setValues( parameters );
	}

	/**
	 * Basic materials are not affected by normal and bump maps so we
	 * return by default {@link normalViewGeometry}.
	 *
	 * @return {Node<vec3>} The normal node.
	 */
	setupNormal() {
		return directionToFaceDirection( normalViewGeometry ); // see #28839
	}

	/**
	 * Overwritten since this type of material uses {@link BasicEnvironmentNode}
	 * to implement the default environment mapping.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {?BasicEnvironmentNode<vec3>} The environment node.
	 */
	BasicEnvironmentNode<vec3>? setupEnvironment( builder ) {
		final envNode = super.setupEnvironment( builder );
		return envNode ? new BasicEnvironmentNode( envNode ) : null;
	}

	/**
	 * This method must be overwritten since light maps are evaluated
	 * with a special scaling factor for basic materials.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {?BasicLightMapNode<vec3>} The light map node.
	 */
	BasicLightMapNode<vec3>? setupLightMap( builder ) {
		let node = null;

		if ( builder.material.lightMap ) {
			node = new BasicLightMapNode( materialLightMap );
		}

		return node;
	}

	/**
	 * The material overwrites this method because `lights` is set to `true` but
	 * we still want to return the diffuse color as the outgoing light.
	 *
	 * @return {Node<vec3>} The outgoing light node.
	 */
	Node<vec3> setupOutgoingLight() {
		return diffuseColor.rgb;
	}

	/**
	 * Setups the lighting model.
	 *
	 * @return {BasicLightingModel} The lighting model.
	 */
	BasicLightingModel setupLightingModel() {
		return BasicLightingModel();
	}
}
