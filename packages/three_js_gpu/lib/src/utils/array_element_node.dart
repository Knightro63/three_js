import '../core/node.dart';

/**
 * Base class for representing element access on an array-like
 * node data structures.
 *
 * @augments Node
 */
class ArrayElementNode extends Node { // @TODO: If extending from TempNode it breaks webgpu_compute
  Node node;
  Node indexNode;

	/**
	 * finalructs an array element node.
	 *
	 * @param {Node} node - The array-like node.
	 * @param {Node} indexNode - The index node that defines the element access.
	 */
	ArrayElementNode(this.node, this.indexNode ):super();

	/**
	 * This method is overwritten since the node type is inferred from the array-like node.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {String} The node type.
	 */
	String getNodeType(NodeBuilder builder ) {
		return this.node.getElementType( builder );
	}

	String generate(NodeBuilder builder ) {
		final indexType = this.indexNode.getNodeType( builder );

		final nodeSnippet = this.node.build( builder );
		final indexSnippet = this.indexNode.build( builder, ! builder.isVector( indexType ) && builder.isInteger( indexType ) ? indexType : 'uint' );

		return '${ nodeSnippet }[ ${ indexSnippet } ]';
	}
}
