import '../core/lighting_model.dart';

/**
 * Represents lighting model for a shadow material. Used in {@link ShadowNodeMaterial}.
 *
 * @augments LightingModel
 */
class ShadowMaskModel extends LightingModel {
  Node shadowNode = float( 1 ).toVar( 'shadowMask' );

	/**
	 * Constructs a new shadow mask model.
	 */
	ShadowMaskModel():super();

	/**
	 * Only used to save the shadow mask.
	 *
	 * @param {Object} input - The input data.
	 */
  @override
	void direct(Map<String, dynamic> lightNode, NodeBuilder builder ) {
		if ( lightNode['shadowNode'] != null ) {
			this.shadowNode.mulAssign( lightNode['shadowNode'] );
		}
	}

	/**
	 * Uses the shadow mask to produce the final color.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	@override
	void finish(NodeBuilder builder) {
		diffuseColor.a.mulAssign( this.shadowNode.oneMinus() );
		builder.context.outgoingLight.rgb.assign( diffuseColor.rgb ); // TODO: Optimize LightsNode to avoid this assignment
	}
}
