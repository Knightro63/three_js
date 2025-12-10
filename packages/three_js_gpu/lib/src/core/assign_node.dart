import '../core/temp_node.dart';
import '../tsl/Ttsl_core.dart';
import '../core/finalants.js';

/**
 * These node represents an assign operation. Meaning a node is assigned
 * to another node.
 *
 * @augments TempNode
 */
class AssignNode extends TempNode {
  Node targetNode;
  Node sourceNode;

	/**
	 * finalructs a new assign node.
	 *
	 * @param {Node} targetNode - The target node.
	 * @param {Node} sourceNode - The source type.
	 */
	AssignNode(this.targetNode, this.sourceNode ):super();

	/**
	 * Whether this node is used more than once in context of other nodes. This method
	 * is overwritten since it always returns `false` (assigns are unique).
	 *
	 * @return {boolean} A flag that indicates if there is more than one dependency to other nodes. Always `false`.
	 */
	bool hasDependencies() {
		return false;
	}

	String getNodeType(NodeBuilder builder, String output ) {
		return output != 'void' ? this.targetNode.getNodeType( builder ) : 'void';
	}

	/**
	 * Whether a split is required when assigning source to target. This can happen when the component length of
	 * target and source data type does not match.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {boolean} Whether a split is required when assigning source to target.
	 */
	bool needsSplitAssign(NodeBuilder builder ) {
		final targetNode = this.targetNode;

		if ( builder.isAvailable( 'swizzleAssign' ) == false && targetNode.isSplitNode && targetNode.components.length > 1 ) {
			final targetLength = builder.getTypeLength( targetNode.node.getNodeType( builder ) );
			final assignDifferentVector = vectorComponents.join( '' ).slice( 0, targetLength ) != targetNode.components;

			return assignDifferentVector;
		}

		return false;
	}

	void setup(NodeBuilder builder ) {
		final { targetNode, sourceNode } = this;

		final properties = builder.getNodeProperties( this );
		properties.sourceNode = sourceNode;
		properties.targetNode = targetNode.context( { assign: true } );
	}

	generate( builder, output ) {

		final { targetNode, sourceNode } = builder.getNodeProperties( this );

		final needsSplitAssign = this.needsSplitAssign( builder );

		final targetType = targetNode.getNodeType( builder );

		final target = targetNode.build( builder );
		final source = sourceNode.build( builder, targetType );

		final sourceType = sourceNode.getNodeType( builder );

		final nodeData = builder.getDataFromNode( this );

		//

		let snippet;

		if ( nodeData.initialized === true ) {

			if ( output !== 'void' ) {

				snippet = target;

			}

		} else if ( needsSplitAssign ) {

			final sourceVar = builder.getVarFromNode( this, null, targetType );
			final sourceProperty = builder.getPropertyName( sourceVar );

			builder.addLineFlowCode( `${ sourceProperty } = ${ source }`, this );

			final splitNode = targetNode.node;
			final splitTargetNode = splitNode.node.context( { assign: true } );

			final targetRoot = splitTargetNode.build( builder );

			for ( let i = 0; i < splitNode.components.length; i ++ ) {

				final component = splitNode.components[ i ];

				builder.addLineFlowCode( `${ targetRoot }.${ component } = ${ sourceProperty }[ ${ i } ]`, this );

			}

			if ( output !== 'void' ) {

				snippet = target;

			}

		} else {

			snippet = `${ target } = ${ source }`;

			if ( output === 'void' || sourceType === 'void' ) {

				builder.addLineFlowCode( snippet, this );

				if ( output !== 'void' ) {

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
export final assign = /*@__PURE__*/ nodeProxy( AssignNode ).setParameterLength( 2 );

addMethodChaining( 'assign', assign );
