import 'package:three_js_core/materials/mesh_standard_material.dart';
import 'package:three_js_core/three_js_core.dart';

final _defaultValues = MeshStandardMaterial();

/**
 * Node material version of {@link MeshStandardMaterial}.
 *
 * @augments NodeMaterial
 */
class MeshStandardNodeMaterial extends NodeMaterial {
	String get type => 'MeshStandardNodeMaterial';
  bool lights = true;

  /**
   * The emissive color of standard materials is by default inferred from the `emissive`,
   * `emissiveIntensity` and `emissiveMap` properties. This node property allows to
   * overwrite the default and define the emissive color with a node instead.
   *
   * If you don't want to overwrite the emissive color but modify the existing
   * value instead, use {@link materialEmissive}.
   */
  Node<vec3>? emissiveNode;

  /**
   * The metalness of standard materials is by default inferred from the `metalness`,
   * and `metalnessMap` properties. This node property allows to
   * overwrite the default and define the metalness with a node instead.
   *
   * If you don't want to overwrite the metalness but modify the existing
   * value instead, use {@link materialMetalness}.
   */
  Node<float>? metalnessNode;

  /**
   * The roughness of standard materials is by default inferred from the `roughness`,
   * and `roughnessMap` properties. This node property allows to
   * overwrite the default and define the roughness with a node instead.
   *
   * If you don't want to overwrite the roughness but modify the existing
   * value instead, use {@link materialRoughness}.
   */
  Node<float>? roughnessNode;

	/**
	 * Constructs a new mesh standard node material.
	 */
	MeshStandardNodeMaterial( parameters ):super(){
		this.setDefaultValues( _defaultValues );
		this.setValues( parameters );
	}

	/**
	 * Overwritten since this type of material uses {@link EnvironmentNode}
	 * to implement the PBR (PMREM based) environment mapping. Besides, the
	 * method honors `Scene.environment`.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {?EnvironmentNode<vec3>} The environment node.
	 */
	EnvironmentNode<vec3>? setupEnvironment( NodeBuilderbuilder ) {
		let envNode = super.setupEnvironment( builder );

		if ( envNode == null && builder.environmentNode ) {
			envNode = builder.environmentNode;
		}

		return envNode ? new EnvironmentNode( envNode ) : null;
	}

	/**
	 * Setups the lighting model.
	 *
	 * @return {PhysicalLightingModel} The lighting model.
	 */
	PhysicalLightingModel setupLightingModel(NodeBuilder builder) {
		return PhysicalLightingModel();
	}

	/**
	 * Setups the specular related node variables.
	 */
	setupSpecular() {
		final specularColorNode = mix( vec3( 0.04 ), diffuseColor.rgb, metalness );

		specularColor.assign( vec3( 0.04 ) );
		specularColorBlended.assign( specularColorNode );
		specularF90.assign( 1.0 );
	}

	/**
	 * Setups the standard specific node variables.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	void setupVariants(NodeBuilder builder) {
		// METALNESS
		final metalnessNode = this.metalnessNode != null? float( this.metalnessNode ) : materialMetalness;

		metalness.assign( metalnessNode );

		// ROUGHNESS
		final roughnessNode = this.roughnessNode != null? float( this.roughnessNode ) : materialRoughness;
		roughnessNode = getRoughness( { roughness: roughnessNode } );

		roughness.assign( roughnessNode );

		// SPECULAR COLOR
		setupSpecular();

		// DIFFUSE COLOR
		diffuseContribution.assign( diffuseColor.rgb.mul( metalnessNode.oneMinus() ) );
	}

	MeshStandardNodeMaterial copy(Object3D source ) {
    source as MeshStandardNodeMaterial;
		super.copy( source );

		emissiveNode = source.emissiveNode;

		metalnessNode = source.metalnessNode;
		roughnessNode = source.roughnessNode;

		return this;
	}
}
