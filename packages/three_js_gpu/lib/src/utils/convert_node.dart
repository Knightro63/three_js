import '../core/node.dart';

/**
 * This module is part of the TSL core and usually not used in app level code.
 * It represents a convert operation during the shader generation process
 * meaning it converts the data type of a node to a target data type.
 *
 * @augments Node
 */
class ConvertNode extends Node {
  Node node;
  String convertTo;

	/**
	 * finalructs a new convert node.
	 *
	 * @param {Node} node - The node which type should be converted.
	 * @param {string} convertTo - The target node type. Multiple types can be defined by separating them with a `|` sign.
	 */
	ConvertNode(this.node, this.convertTo ):super();

	/**
	 * This method is overwritten since the implementation tries to infer the best
	 * matching type from the {@link ConvertNode#convertTo} property.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {string} The node type.
	 */
	String? getNodeType(NodeBuilder builder ) {
		final requestType = this.node.getNodeType( builder );
		String? convertTo;

		for ( final overloadingType of this.convertTo.split( '|' ) ) {
			if ( convertTo == null || builder.getTypeLength( requestType ) == builder.getTypeLength( overloadingType ) ) {
				convertTo = overloadingType;
			}
		}

		return convertTo;
	}

	void serialize( data ) {
		super.serialize( data );
		data.convertTo = this.convertTo;
	}

	void deserialize( data ) {
		super.deserialize( data );
		this.convertTo = data.convertTo;
	}

	generate(NodeBuilder builder, output ) {
		final node = this.node;
		final type = this.getNodeType( builder );

		final snippet = node.build( builder, type );

		return builder.format( snippet, type, output );
	}
}
