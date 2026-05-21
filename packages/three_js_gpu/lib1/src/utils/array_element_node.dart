import 'package:three_js_gpu/src/code/node_builder.dart';

import '../core/node.dart';

/// Base class for representing element access on an array-like
/// node data structures.
class ArrayElementNode extends Node { // @TODO: If extending from TempNode it breaks webgpu_compute
  Node node;
  Node indexNode;

	ArrayElementNode(this.node, this.indexNode ):super();

  /// This method is overwritten since the node type is inferred from the array-like node.
  @override
	String getNodeType(NodeBuilder builder, [String? output]  ) {
		return node.getElementType( builder );
	}

  @override
	String generate(NodeBuilder builder, [String? output] ) {
		final indexType = indexNode.getNodeType( builder );

		final nodeSnippet = node.build( builder );
		final indexSnippet = indexNode.build( builder, ! builder.isVector( indexType ) && builder.isInteger( indexType ) ? indexType : 'uint' );

		return '$nodeSnippet[ $indexSnippet]';
	}
}
