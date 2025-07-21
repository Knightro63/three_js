import "package:three_js_gpu/common/uniform_buffer.dart";
import "package:three_js_math/three_js_math.dart";

int _id = 0;

/**
 * A special form of uniform buffer binding type.
 * It's buffer value is managed by a node object.
 *
 * @private
 * @augments UniformBuffer
 */
class NodeUniformBuffer extends UniformBuffer {
  BufferNode nodeUniform;
  UniformGroupNode groupNode;
	/**
	 * Constructs a new node-based uniform buffer.
	 *
	 * @param {BufferNode} nodeUniform - The uniform buffer node.
	 * @param {UniformGroupNode} groupNode - The uniform group node.
	 */
	NodeUniformBuffer( this.nodeUniform, this.groupNode ):super( 'UniformBuffer_${_id ++}', nodeUniform != null ? nodeUniform.value : null );
	

	Float32Array get buffer => this.nodeUniform.value;
}
