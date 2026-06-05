import '../code/node_builder.dart';
import '../core/node.dart';
import '../core/temp_node.dart';

/// These node represents an assign operation. Meaning a node is assigned
/// to another node.
class AssignNode extends TempNode {
  Node targetNode;
  Node sourceNode;

	AssignNode(this.targetNode, this.sourceNode ):super();

	/// Whether this node is used more than once in context of other nodes. This method
	/// is overwritten since it always returns `false` (assigns are unique).
  @override
	bool hasDependencies(NodeBuilder builder) {
		return false;
	}

  @override
	String getNodeType(NodeBuilder builder, [String? output] ) {
		return output != 'void' ? this.targetNode.getNodeType( builder ) : 'void';
	}

  /// Whether a split is required when assigning source to target. This can happen when the component length of
	/// target and source data type does not match.
	bool needsSplitAssign(NodeBuilder builder ) {
		final targetNode = this.targetNode;

		if ( builder.isAvailable( 'swizzleAssign' ) == false && targetNode is SplitNode && targetNode.components.length > 1 ) {
			final targetLength = builder.getTypeLength( targetNode.node.getNodeType( builder ) );
			final assignDifferentVector = vectorComponents.join( '' ).slice( 0, targetLength ) != targetNode.components;

			return assignDifferentVector;
		}

		return false;
	}

  @override
	Node? setup(NodeBuilder builder ) {
		final targetNode = this.targetNode;
    final sourceNode = this.sourceNode;

		final properties = builder.getNodeProperties( this );
		properties.sourceNode = sourceNode;
		properties.targetNode = targetNode.context( { assign: true } );

    return null;
	}

  @override
	generate(NodeBuilder builder, [String? output] ) {

		final gnp = builder.getNodeProperties( this );

    final targetNode = gnp.targetNode;
    final sourceNode = gnp.sourceNode;

		final needsSplitAssign = this.needsSplitAssign( builder );

		final targetType = targetNode.getNodeType( builder );

		final target = targetNode.build( builder );
		final source = sourceNode.build( builder, targetType );

		final sourceType = sourceNode.getNodeType( builder );

		final nodeData = builder.getDataFromNode( this );

		//

		late String snippet;
		if ( nodeData.initialized == true ) {
			if ( output != 'void' ) {
				snippet = target;
			}
		} 
    else if ( needsSplitAssign ) {
			final sourceVar = builder.getVarFromNode( this, null, targetType );
			final sourceProperty = builder.getPropertyName( sourceVar );

			builder.addLineFlowCode( '$sourceProperty = $source', this );

			final splitNode = targetNode.node;
			final splitTargetNode = splitNode.node.context( { assign: true } );

			final targetRoot = splitTargetNode.build( builder );

			for (int i = 0; i < splitNode.components.length; i ++ ) {
				final component = splitNode.components[ i ];
				builder.addLineFlowCode( '$targetRoot.$component = $sourceProperty[ $i ]', this );
			}

			if ( output != 'void' ) {
				snippet = target;
			}
		} 
    else {
			snippet = '$target = $source';

			if ( output == 'void' || sourceType == 'void' ) {
				builder.addLineFlowCode( snippet, this );

				if ( output != 'void' ) {
					snippet = target;
				}
			}
		}

		nodeData.initialized = true;

		return builder.format( snippet, targetType, output );
	}
}

/**
 * TSL function for creating an assign node.
 *
 * @tsl
 * @function
 * @param {Node} targetNode - The target node.
 * @param {Node} sourceNode - The source type.
 * @returns {AssignNode}
 */
final assign = /*@__PURE__*/ nodeProxy( AssignNode ).setParameterLength( 2 );

addMethodChaining( 'assign', assign );
