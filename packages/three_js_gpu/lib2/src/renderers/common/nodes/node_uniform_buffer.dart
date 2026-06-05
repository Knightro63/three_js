import "dart:typed_data";

import "../../../nodes/core/uniform_group_node.dart";
import "../uniform_buffer.dart";
import "package:three_js_math/three_js_math.dart";

int _id = 0;

/// A special form of uniform buffer binding type.
/// It's buffer value is managed by a node object.
class NodeUniformBuffer extends UniformBuffer {
  BufferNode nodeUniform;
  UniformGroupNode groupNode;

	NodeUniformBuffer( this.nodeUniform, this.groupNode ):super( 'UniformBuffer_${_id ++}', nodeUniform != null ? nodeUniform.value : null );
	

	Float32List get buffer => this.nodeUniform.value;
}
