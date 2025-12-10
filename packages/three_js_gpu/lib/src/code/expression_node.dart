import '../core/node.dart';
import '../tsl/tsl_core.dart';

enum NodeType{void}

/**
 * This class can be used to implement basic expressions in shader code.
 * Basic examples for that are `return`, `continue` or `discard` statements.
 *
 * @augments Node
 */
class ExpressionNode extends Node {
  String snippet;
  NodeType nodeType = NodeType.void;

	/**
	 * constructs a new expression node.
	 *
	 * @param {string} [snippet=''] - The native code snippet.
	 * @param {string} [nodeType='void'] - The node type.
	 */
	ExpressionNode([this.snippet = '', this.nodeType = 'void' ]):super( nodeType );

	generate(NodeBuilder builder, output ) {
		final type = this.getNodeType( builder );
		final snippet = this.snippet;

		if ( type == 'void' ) {
			builder.addLineFlowCode( snippet, this );
		} 
    else {
			return builder.format( snippet, type, output );
		}
	}
}

/**
 * TSL function for creating an expression node.
 *
 * @tsl
 * @function
 * @param {string} [snippet] - The native code snippet.
 * @param {?string} [nodeType='void'] - The node type.
 * @returns {ExpressionNode}
 */
export final expression = /*@__PURE__*/ nodeProxy( ExpressionNode ).setParameterLength( 1, 2 );
