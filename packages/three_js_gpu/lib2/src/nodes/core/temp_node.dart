import '../code/node_builder.dart';
import '../core/node.dart';

/// This module uses cache management to create temporary variables
/// if the node is used more than once to prevent duplicate calculations.
///
/// The class acts as a base class for many other nodes types.
class TempNode extends Node {

  @override
	get type {
		return 'TempNode';
	}

	TempNode([super.nodeType]);

	/// Whether this node is used more than once in context of other nodes.
	bool hasDependencies(NodeBuilder builder ) {
		return builder.getDataFromNode( this ).usageCount > 1;
	}

	@override
  dynamic build(NodeBuilder builder, [String? output] ) {
		final buildStage = builder.getBuildStage();

		if ( buildStage == 'generate' ) {
			final type = builder.getVectorType( getNodeType( builder, output ) );
			final nodeData = builder.getDataFromNode( this );

			if ( nodeData.propertyName != null ) {
				return builder.format( nodeData.propertyName, type, output );
			} 
      else if ( type != 'void' && output != 'void' && hasDependencies( builder ) ) {
				final snippet = super.build( builder, type );

				final nodeVar = builder.getVarFromNode( this, null, type );
				final propertyName = builder.getPropertyName( nodeVar );

				builder.addLineFlowCode( '$propertyName = $snippet', this );

				nodeData.snippet = snippet;
				nodeData.propertyName = propertyName;

				return builder.format( nodeData.propertyName, type, output );
			}
		}

		return super.build( builder, output );
	}
}