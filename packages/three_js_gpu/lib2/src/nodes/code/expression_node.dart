import 'node_builder.dart';
import '../core/node.dart';
import '../tsl/tsl_core.dart';

/// This class can be used to implement basic expressions in shader code.
/// Basic examples for that are `return`, `continue` or `discard` statements.
class ExpressionNode extends Node {
  String snippet;

	ExpressionNode([this.snippet = '', super.nodeType = 'void' ]);

	@override
	String? generate(NodeBuilder builder, String? output ) {
		final type = getNodeType( builder );
		final snippet = this.snippet;

		if ( type == 'void' ) {
			builder.addLineFlowCode( snippet, this );
		} 
    else {
			return builder.format( snippet, type, output );
		}

    return null;
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
final expression = /*@__PURE__*/ nodeProxy( ExpressionNode ).setParameterLength( 1, 2 );
