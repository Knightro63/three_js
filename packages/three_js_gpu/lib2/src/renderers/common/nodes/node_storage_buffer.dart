import "../../../nodes/core/constants.dart";
import "../../../nodes/core/uniform_group_node.dart";
import "../storage_buffer.dart";
import "package:three_js_math/three_js_math.dart";

int _id = 0;

/// A special form of storage buffer binding type.
/// It's buffer value is managed by a node object.
class NodeStorageBuffer extends StorageBuffer {
  StorageBufferNode nodeUniform;
  UniformGroupNode groupNode;
  String access;

	NodeStorageBuffer(this.nodeUniform, groupNode ):super( 'StorageBuffer_${_id ++}', nodeUniform != null? nodeUniform.value : null ){
		this.access = nodeUniform != null? nodeUniform.access : NodeAccess.readWrite;
	}

	/// The storage buffer.
	BufferAttribute get buffer => this.nodeUniform.value;
}
