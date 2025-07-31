import "package:three_js_gpu/common/storage_buffer.dart";
import "package:three_js_math/three_js_math.dart";

int _id = 0;

/**
 * A special form of storage buffer binding type.
 * It's buffer value is managed by a node object.
 *
 * @private
 * @augments StorageBuffer
 */
class NodeStorageBuffer extends StorageBuffer {
  StorageBufferNode nodeUniform;
  UniformGroupNode groupNode;
  String access;

	/**
	 * Constructs a new node-based storage buffer.
	 *
	 * @param {StorageBufferNode} nodeUniform - The storage buffer node.
	 * @param {UniformGroupNode} groupNode - The uniform group node.
	 */
	NodeStorageBuffer(this.nodeUniform, groupNode ):super( 'StorageBuffer_${_id ++}', nodeUniform != null? nodeUniform.value : null ){
		this.access = nodeUniform != null? nodeUniform.access : NodeAccess.READ_WRITE;
	}

	/**
	 * The storage buffer.
	 *
	 * @type {BufferAttribute}
	 */
	BufferAttribute get buffer => this.nodeUniform.value;

}
