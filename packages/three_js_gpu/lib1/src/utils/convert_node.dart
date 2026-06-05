import '../../src/code/node_builder.dart';
import '../core/node.dart';

/// This module is part of the TSL core and usually not used in app level code.
/// It represents a convert operation during the shader generation process
/// meaning it converts the data type of a node to a target data type.
class ConvertNode extends Node {
  Node node;
  String convertTo;

	ConvertNode(this.node, this.convertTo ):super();

	/// This method is overwritten since the implementation tries to infer the best
	/// matching type from the {@link ConvertNode#convertTo} property.
  @override
	String? getNodeType(NodeBuilder builder, [String? output] ) {
		final requestType = node.getNodeType( builder );
		String? convertTo;

		for ( final overloadingType in this.convertTo.split( '|' ) ) {
			if ( convertTo == null || builder.getTypeLength( requestType ) == builder.getTypeLength( overloadingType ) ) {
				convertTo = overloadingType;
			}
		}

		return convertTo;
	}

  @override
	void serialize( data ) {
		super.serialize( data );
		data.convertTo = convertTo;
	}

  @override
	void deserialize( data ) {
		super.deserialize( data );
		convertTo = data.convertTo;
	}

  @override
	String? generate(NodeBuilder builder, [String? output] ) {
		final node = this.node;
		final type = getNodeType( builder );

		final snippet = node.build( builder, type );

		return builder.format( snippet, type, output );
	}
}
