import 'package:three_js_gpu/src/code/node_builder.dart';
import 'package:three_js_gpu/src/core/node.dart';

import './temp_node.dart';
import '../tsl/tsl_core.dart';

/// ArrayNode represents a collection of nodes, typically created using the {@link array} function.
/// ```js
/// const colors = array( [
/// 	vec3( 1, 0, 0 ),
/// 	vec3( 0, 1, 0 ),
/// 	vec3( 0, 0, 1 )
/// ] );
///
/// const redColor = tintColors.element( 0 );
///
class ArrayNode extends TempNode {
  int count;
  List<Node>? values;
  String? nodeType;

	ArrayNode(this.nodeType, this.count, [super.values]);

	/// Returns the node's type.
	String? getNodeType(NodeBuilder builder ) {
		nodeType ??= values?[ 0 ].getNodeType( builder );
		return nodeType;
	}

	String getElementType(NodeBuilder builder ) {
		return this.getNodeType( builder );
	}

	/// This method builds the output node and returns the resulting array as a shader string.
	String generate(NodeBuilder builder ) {
		final type = getNodeType( builder );
		return builder.generateArray( type, count, this.values );
	}
}

/**
 * TSL function for creating an array node.
 *
 * @tsl
 * @function
 * @param {string|Array<Node>} nodeTypeOrValues - A string representing the element type (e.g., 'vec3')
 * or an array containing the default values (e.g., [ vec3() ]).
 * @param {?number} [count] - Size of the array.
 * @returns {ArrayNode}
 */
// const array = ( ...params ) => {

// 	let node;

// 	if ( params.length === 1 ) {

// 		const values = params[ 0 ];

// 		node = new ArrayNode( null, values.length, values );

// 	} else {

// 		const nodeType = params[ 0 ];
// 		const count = params[ 1 ];

// 		node = new ArrayNode( nodeType, count );

// 	}

// 	return nodeObject( node );

// };

// addMethodChaining( 'toArray', ( node, count ) => array( Array( count ).fill( node ) ) );
